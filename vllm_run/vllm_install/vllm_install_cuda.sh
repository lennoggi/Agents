#!/bin/bash
# =================================================================
# NOTE: execute this script from a compute node if the login node's
#       architecture differs from the compute nodes' architecture
# =================================================================
set -euo pipefail

# -----------------------
# User-defined parameters
# -----------------------
INSTALL_DIR="/scrt1/D/cibo/cibo39/vllm_install_cuda"
VENV="$INSTALL_DIR/vllm-env"
# -----------------------

mkdir -p $INSTALL_DIR
cd $INSTALL_DIR

ml python/3.12.12
ml cuda/13.0.2

export UV_CACHE_DIR="$INSTALL_DIR/uv_cache"

python3 -m pip install --upgrade pip
python3 -m pip install uv

uv venv "$VENV" --python 3.12.12 --seed --managed-python
. $VENV/bin/activate

uv pip install "ray[cgraph]"
uv pip install "vllm[bench]" --torch-backend=auto

deactivate
echo "vLLM successfully installed under $INSTALL_DIR"
