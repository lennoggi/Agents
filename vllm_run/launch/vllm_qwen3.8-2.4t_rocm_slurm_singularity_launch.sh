#!/bin/bash

set -euo pipefail


# -----------------------
# User-defined parameters
# -----------------------
SINGULARITY_IMAGE="/path/to/user/scratch/singularity_images/vllm-openai-rocm_v0.30.0_ray.sif"
export SINGULARITY_CACHEDIR="/path/to/user/scratch/singularity_cache"

export MODEL_PATH="/path/to/hf_home/hub/models--Qwen--Qwen3.8-2.4T-A95B/snapshots/207bd685a7e3696cfaff12ded7c6a7ea0f88c996"
export MODEL_NAME="Qwen3.8-2.4T-A95B"

export HF_HOME="/path/to/hf_home"

export TMPDIR="/tmp/$USER"  # Node-local, fast I/O
export TMPHOME="$TMPDIR/home"
export RAY_TMPDIR="$TMPDIR/ray_tmp_$SLURM_JOBID"

# NOTE: redirect cache directories to node-local paths to prevent multiple Ray
#       workers from racing for the same files
export AMD_COMGR_CACHE_DIR="$TMPDIR/rocm_cache"
export TRITON_CACHE_DIR="$TMPDIR/triton_cache"
export VLLM_CACHE_ROOT="$TMPDIR/vllm_cache"
export TORCHINDUCTOR_CACHE_DIR="$TMPDIR/torch_inductor_cache"
export FLASHINFER_WORKSPACE_BASE="$TMPDIR/flashinfer_workspace_base"

VLLM_PORT=8000
RAY_PORT=6379
VLLM_API_KEY="my-vllm-key"


# ----------
# Trap setup
# ----------
SING="singularity exec --rocm --no-home -B "$TMPDIR":"$TMPDIR":rw,"$HF_HOME":"$HF_HOME":ro "$SINGULARITY_IMAGE""
trap '$SING ray stop; rm -rf $TMPDIR' EXIT INT TERM ERR


# -----------------
# Environment setup
# -----------------
rm -rf $TMPDIR
mkdir -p $TMPDIR $TMPHOME $RAY_TMPDIR $AMD_COMGR_CACHE_DIR $TRITON_CACHE_DIR $VLLM_CACHE_ROOT $TORCHINDUCTOR_CACHE_DIR $FLASHINFER_WORKSPACE_BASE

unset OMP_NUM_THREADS


# -----------------------------------------------------
# Redirect stdout and stderr to separate per-node files
# -----------------------------------------------------
exec > "$SLURM_SUBMIT_DIR/$(hostname -s).out" 2> "$SLURM_SUBMIT_DIR/$(hostname -s).err"


# -------------------------------
# Node identity and network setup
# -------------------------------
INFO_STR="Running on $SLURM_NNODES nodes with $SLURM_CPUS_PER_TASK CPUs and $SLURM_GPUS_PER_NODE GPUs per node"
printf '%*s' "${#INFO_STR}" '' | tr ' ' '='
echo ""
echo $INFO_STR
printf '%*s' "${#INFO_STR}" '' | tr ' ' '='
echo ""

THIS_NODE_SHORT=$(hostname -s)
HEAD_NODE_SHORT=$(scontrol show hostnames $SLURM_NODELIST | head -n 1)

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

export HIP_VISIBLE_DEVICES=$(seq -s, 0 $((SLURM_GPUS_PER_NODE - 1)))


# ---
# Run
# ---
# ***** Head node *****
if [[ "$THIS_NODE_SHORT" == "$HEAD_NODE_SHORT" ]]
then
    RAY_START_HEAD_CMD="ray start --head \
--node-ip-address $HEAD_IP \
--port $RAY_PORT \
--num-gpus $SLURM_GPUS_PER_NODE \
--temp-dir "$RAY_TMPDIR""

    $SING bash -c "$RAY_START_HEAD_CMD"

    echo "Waiting for $SLURM_NNODES nodes..."
    NWAIT=60

    for i in $(seq 1 $NWAIT); do
        LIVE=$($SING ray status 2>&1 | sed -n '/^Active:/,/^Pending:/p' | grep -c "node_" || true)
        echo "  $LIVE/$SLURM_NNODES live nodes detected (attempt $i/$NWAIT)"
        [[ "$LIVE" -ge "$SLURM_NNODES" ]] && break
        sleep 5
    done

    $SING ray status

    VLLM_CMD="vllm serve "$MODEL_PATH" \
--served-model-name "$MODEL_NAME" \
--api-key "$VLLM_API_KEY" \
--distributed-executor-backend ray \
--tensor-parallel-size $SLURM_GPUS_PER_NODE \
--pipeline-parallel-size $SLURM_NNODES \
--host 0.0.0.0 \
--port $VLLM_PORT \
--dtype auto \
--trust-remote-code \
--enable-expert-parallel \
--enable-prefix-caching \
--enable-chunked-prefill \
--enable-auto-tool-choice \
--tool-call-parser qwen3_coder \
--reasoning-parser qwen3 \
--max-model-len 2048 \
--max-num-batched-tokens 512 \
--cpu-offload-gb 8 \
--skip-mm-profiling \
--limit-mm-per-prompt.video 0 \
--limit-mm-per-prompt.image 0"

##--max-model-len 2048 \
##--max-num-seqs 1 \
##--max-num-batched-tokens 512 \
##--kv-cache-memory-bytes 512M \
##--enforce-eager \
##--cpu-offload-gb 16 \
##--cpu-offload-params experts"  #XXX: not needed if all the flags above are active

##--enforce-eager \
##--disable-custom-all-reduce \

    $SING bash -c "$VLLM_CMD"

# ***** Worker nodes *****
else
    RAY_START_WORKER_CMD="ray start --block \
--node-ip-address $THIS_IP \
--address $HEAD_IP:$RAY_PORT \
--num-gpus $SLURM_GPUS_PER_NODE \
--temp-dir "$RAY_TMPDIR""

    $SING bash -c "$RAY_START_WORKER_CMD"
fi
