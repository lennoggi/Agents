#!/bin/bash

set -euo pipefail

# -----------------------
# User-defined parameters
# -----------------------
INSTALL_DIR="/path/to/user/scratch/vllm_install_rocm"
VENV="$INSTALL_DIR/vllm-env"
RAY_WHEELS_DIR="$INSTALL_DIR/ray_wheels"
VLLM_ROCM_WHEELS_DIR="$INSTALL_DIR/vllm_rocm_wheels"
# -----------------------

mkdir -p $INSTALL_DIR
cd $INSTALL_DIR

ml python/3.12.12-gcc-10.5.0-kdztpxl
ml rocm/7.1.1--binary

export UV_CACHE_DIR="$INSTALL_DIR/uv_cache"

python3 -m ensurepip --upgrade
python3 -m pip install --upgrade pip
python3 -m pip install uv

uv venv "$VENV" --python 3.12.12 --seed --managed-python
. $VENV/bin/activate

##uv pip download "ray[cgraph]" --destination $RAY_WHEELS_DIR
##python3 -m pip download "ray[cgraph]" --dest $RAY_WHEELS_DIR

##uv pip download "vllm[bench]" --extra-index-url https://wheels.vllm.ai/rocm/ --destination $VLLM_ROCM_WHEELS_DIR
python3 -m pip download "vllm[bench]" --extra-index-url https://wheels.vllm.ai/rocm/ --dest $VLLM_ROCM_WHEELS_DIR

deactivate
echo "vLLM successfully downloaded under $INSTALL_DIR"
