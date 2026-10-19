#!/bin/bash

set -euo pipefail

# -----------------------
# User-defined parameters
# -----------------------
INSTALL_DIR="/path/to/user/scratch/ray_install_rocm"
VENV="$INSTALL_DIR/ray-env"
# -----------------------

mkdir -p $INSTALL_DIR
cd $INSTALL_DIR

ml gcc/14.2.0-gcc-10.5.0-32fqk37
ml python/3.12.12-gcc-10.5.0-kdztpxl
ml rocm/7.1.1--binary

export UV_CACHE_DIR="$INSTALL_DIR/uv_cache"
##export UV_TORCH_BACKEND="rocm7.1"

python3 -m ensurepip --upgrade
python3 -m pip install --upgrade pip
python3 -m pip install uv

uv venv "$VENV" --python 3.12.12 --seed --managed-python
. $VENV/bin/activate

##uv pip install "ray[cgraph]"
uv pip install ray[all]==2.51.1

deactivate
echo "Ray successfully installed under $INSTALL_DIR"
