#!/bin/bash

set -euo pipefail

# -----------------------
# User-defined parameters
# -----------------------
export MODEL_PATH="/path/to/hf_home/hub/models--Qwen--Qwen3-Coder-Next/snapshots/a7fbcb5c0e12d62a448eaa0e260346bf5dcc0feb"
export MODEL_NAME="Qwen3-Coder-Next"

export HF_HOME="/path/to/hf_home"

export TMPDIR="/tmp/$USER"  # Node-local, fast I/O
export TMPHOME="$TMPDIR/home"
export RAY_TMPDIR="$TMPDIR/ray_tmp_$PBS_JOBID"

# NOTE: redirect cache directories to node-local paths to prevent multiple Ray
#       workers from racing for the same files
export CUDA_CACHE_PATH="$TMPDIR/cuda_cache"
export TRITON_CACHE_DIR="$TMPDIR/triton_cache"
export VLLM_CACHE_ROOT="$TMPDIR/vllm_cache"
export TORCHINDUCTOR_CACHE_DIR="$TMPDIR/torch_inductor_cache"
export FLASHINFER_WORKSPACE_BASE="$TMPDIR/flashinfer_workspace_base"

VLLM_PORT=8000
RAY_PORT=6379
VLLM_API_KEY="my-vllm-key"


# -----------------
# Environment setup
# -----------------
##module purge
ml $PYTHON_MODULE
ml $CUDA_MODULE
. $VENV/bin/activate

rm -rf $TMPDIR
mkdir -p $TMPDIR $TMPHOME $RAY_TMPDIR $CUDA_CACHE_PATH $TRITON_CACHE_DIR $VLLM_CACHE_ROOT $TORCHINDUCTOR_CACHE_DIR $FLASHINFER_WORKSPACE_BASE

unset OMP_NUM_THREADS


# ----------
# Trap setup
# ----------
trap 'ray stop; rm -rf $TMPDIR' EXIT INT TERM ERR


# -----------------------------------------------------
# Redirect stdout and stderr to separate per-node files
# -----------------------------------------------------
exec > "$PBS_O_WORKDIR/$(hostname -s).out" 2> "$PBS_O_WORKDIR/$(hostname -s).err"


# -------------------------------
# Node identity and network setup
# -------------------------------
NNODES=$(sort -u $PBS_NODEFILE | wc -l)

echo "==================================================="
echo "Running on $NNODES nodes with $NCPUS CPUs and $NGPUS GPUs per node"
echo "==================================================="

THIS_NODE_SHORT=$(hostname -s)
HEAD_NODE_SHORT=$(sort -u $PBS_NODEFILE | head -n 1 | cut -d. -f1)

THIS_IP=$(getent ahostsv4 "$THIS_NODE_SHORT" | awk 'NR==1 {print $1}')
HEAD_IP=$(getent ahostsv4 "$HEAD_NODE_SHORT" | awk 'NR==1 {print $1}')

export MASTER_ADDR=$HEAD_IP
export MASTER_PORT=$RAY_PORT
export RAY_ADDRESS="${HEAD_IP}:$RAY_PORT"
export VLLM_HOST_IP=$THIS_IP
export HOST_IP=$THIS_IP


# ------------------------------
# Additional configuration flags
# ------------------------------
export HF_HUB_OFFLINE=1
export HF_DATASETS_OFFLINE=1
export TRANSFORMERS_OFFLINE=1

export RAY_LOG_LEVEL=CRITICAL       # DEBUG | INFO | WARNING | ERROR | CRITICAL
export RAY_BACKEND_LOG_LEVEL=DEBUG  # DEBUG | INFO | WARNING | ERROR | CRITICAL
export RAY_BACKEND_LOG_LEVEL=DEBUG  # DEBUG | INFO | WARNING | ERROR
export RAY_DEDUP_LOGS=1             # Suppress duplicate log lines

export NCCL_DEBUG=INFO
export NCCL_NET_GDR_LEVEL=SYS
export NCCL_P2P_LEVEL=SYS

export VLLM_LOGGING_LEVEL=DEBUG  # DEBUG | INFO | WARNING | ERROR | CRITICAL

export CUDA_VISIBLE_DEVICES=$(seq -s, 0 $((NGPUS - 1)))


# ---
# Run
# ---
# ***** Head node *****
if [[ "$THIS_NODE_SHORT" == "$HEAD_NODE_SHORT" ]]
then
    ray start --head \
        --node-ip-address $HEAD_IP \
        --port $RAY_PORT \
        --num-gpus $NGPUS \
        --temp-dir "$RAY_TMPDIR"

    echo "Waiting for $NNODES nodes..."
    NWAIT=60

    for i in $(seq 1 $NWAIT); do
        LIVE=$(ray status 2>&1 | sed -n '/^Active:/,/^Pending:/p' | grep -c "node_" || true)
        echo "  $LIVE/$NNODES live nodes detected (attempt $i/$NWAIT)"
        [[ "$LIVE" -ge "$NNODES" ]] && break
        sleep 5
    done

    ray status

    vllm serve "$MODEL_PATH" \
        --served-model-name "$MODEL_NAME" \
        --api-key "$VLLM_API_KEY" \
        --distributed-executor-backend ray \
        --tensor-parallel-size $NGPUS \
        --pipeline-parallel-size $NNODES \
        --host 0.0.0.0 \
        --port $VLLM_PORT \
        --dtype auto \
        --trust-remote-code \
        --enable-expert-parallel \
        --enable-prefix-caching \
        --enable-chunked-prefill \
        --enable-auto-tool-choice \
        --tool-call-parser qwen3_coder

##        --reasoning-parser qwen3 \  ## XXX: Qwen3-Coder-Next does NOT support thinking, so this flag makes vLLM try parsing <think> blocks that never come. DON'T USE IT!
##        --enforce-eager \
##        --disable-custom-all-reduce \

# ***** Worker nodes *****
else
    ray start --block \
        --node-ip-address $THIS_IP \
        --address $HEAD_IP:$RAY_PORT \
        --num-gpus $NGPUS \
        --temp-dir "$RAY_TMPDIR"
fi
