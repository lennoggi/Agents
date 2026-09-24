#!/bin/bash

set -euo pipefail

# ---------------
# Input variables
# ---------------
[[ $# -eq 6 ]] || { echo "Usage: ${BASH_SOURCE[0]} PYTHON_MODULE CUDA_MODULE VENV NODEFILE NCPUS NGPUS" >&2; exit 1; }

export PYTHON_MODULE=$1
export CUDA_MODULE=$2
export VENV=$3
export NODEFILE=$4
export NCPUS=$5
export NGPUS=$6


# -----------------------
# User-defined parameters
# -----------------------
export MODEL_PATH="/scrt1/D/cibo/cibo4/models/hub/models--Qwen--Qwen3-Coder-Next/snapshots/a7fbcb5c0e12d62a448eaa0e260346bf5dcc0feb"
export MODEL_NAME="Qwen3-Coder-Next"

export HF_HOME="/scrt1/D/cibo/cibo4/models"

##export WORKDIR="/work/scr01/cibo39"  # Node-local, fast I/O
export WORKDIR="/tmp/cibo39"  # Node-local, fast I/O
export WORKHOME="$WORKDIR/home"
export RAY_TMP_DIR="$WORKDIR/ray_tmp_$PBS_JOBID"

# NOTE: redirect cache directories to node-local paths to prevent multiple Ray
#       workers from racing for the same files
export CUDA_CACHE_PATH="$WORKDIR/cuda_cache"
export TRITON_CACHE_DIR="$WORKDIR/triton_cache"
export VLLM_CACHE_ROOT="$WORKDIR/vllm_cache"
export TORCHINDUCTOR_CACHE_DIR="$WORKDIR/torch_inductor_cache"
export FLASHINFER_WORKSPACE_BASE="$WORKDIR/flashinfer_workspace_base"

VLLM_PORT=8000
RAY_PORT=6379
VLLM_API_KEY="token-abc123"


# -----------------
# Environment setup
# -----------------
##module purge
ml $PYTHON_MODULE
ml $CUDA_MODULE
. $VENV/bin/activate

rm -rf $WORKDIR
mkdir -p $WORKDIR $WORKHOME $RAY_TMP_DIR $CUDA_CACHE_PATH $TRITON_CACHE_DIR $VLLM_CACHE_ROOT $TORCHINDUCTOR_CACHE_DIR $FLASHINFER_WORKSPACE_BASE

unset OMP_NUM_THREADS


# -----------------------------------------------------
# Redirect stdout and stderr to separate per-node files
# -----------------------------------------------------
exec > "$PBS_O_WORKDIR/$(hostname -s).out" 2> "$PBS_O_WORKDIR/$(hostname -s).err"


# -------------------------------
# Node identity and network setup
# -------------------------------
NNODES=$(sort -u $NODEFILE | wc -l)

echo "==================================================="
echo "Running on $NNODES nodes with $NCPUS CPUs and $NGPUS GPUs per node"
echo "==================================================="

THIS_NODE_SHORT=$(hostname -s)
HEAD_NODE_SHORT=$(sort -u $NODEFILE | head -1 | cut -d. -f1)

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
if [[ "$THIS_NODE_SHORT" == "$HEAD_NODE_SHORT" ]]; then
    ray start --head \
        --node-ip-address $HEAD_IP \
        --port $RAY_PORT \
        --num-gpus $NGPUS \
        --temp-dir $RAY_TMP_DIR

    echo "Waiting for $NNODES nodes..."
    NWAIT=60

    for i in $(seq 1 $NWAIT); do
        LIVE=$(ray status 2>&1 | sed -n '/^Active:/,/^Pending:/p' | grep -c "node_" || true)
        echo "  $LIVE/$NNODES live nodes detected (attempt $i/$NWAIT)"
        [[ "$LIVE" -ge "$NNODES" ]] && break
        sleep 5
    done

    ray status

##    python3 -m vllm.entrypoints.openai.api_server \
    vllm serve \
        --model $MODEL_PATH \
        --served-model-name $MODEL_NAME \
        --api-key $VLLM_API_KEY \
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
        --temp-dir $RAY_TMP_DIR
fi

trap 'deactivate; rm -rf $WORKDIR' EXIT INT TERM ERR
