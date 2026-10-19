#!/bin/bash

set -euo pipefail

# -----------------------
# User-defined parameters
# -----------------------
INSTALL_DIR="path/to/user/scratch/vllm_install_rocm"
VENV="$INSTALL_DIR/vllm-env"
# -----------------------

mkdir -p $INSTALL_DIR
cd $INSTALL_DIR

ml gcc/14.2.0-gcc-10.5.0-32fqk37
ml python/3.12.12-gcc-10.5.0-kdztpxl
ml rocm/7.1.1--binary

export UV_CACHE_DIR="$INSTALL_DIR/uv_cache"
export UV_TORCH_BACKEND="rocm7.1"
export PYTORCH_ROCM_ARCH="gfx90a"

python3 -m ensurepip --upgrade
python3 -m pip install --upgrade pip
python3 -m pip install uv
python3 -m pip install numpy

uv venv "$VENV" --python 3.12.12 --seed --managed-python
. $VENV/bin/activate





# Prevent uv from pulling default CUDA-compiled libraries
uv pip install torch==2.13.0+rocm7.1 torchvision torchaudio --index-url https://download.pytorch.org/whl/rocm7.1

python - <<'PY'
import torch

print("torch:", torch.__version__)
print("HIP:", torch.version.hip)
print("CUDA:", torch.version.cuda)

assert torch.version.hip is not None
assert torch.version.cuda is None
PY




##uv pip install triton-rocm pytorch-triton-rocm --index "https://download.pytorch.org/whl/rocm7.1"
##uv pip install amdsmi
####uv pip install --extra-index-url https://amd.com "flash-attn==2.8.3"

##git clone https://github.com/kvcache-ai/Mooncake.git
##cd Mooncake
##git checkout v0.3.13.post1
##git submodule update --init --recursive

TORCH_CMAKE_DIR="${VENV}/lib/python3.12/site-packages/torch/share/cmake/Torch"
TORCH_CONFIG_FILE="${TORCH_CMAKE_DIR}/TorchConfig.cmake"
FAKE_LIBDRM_DIR="${TORCH_CMAKE_DIR}/fake_libdrm_dir"

mkdir $FAKE_LIBDRM_DIR

cat << EOF > "${TORCH_CONFIG_FILE}.tmp"
# AMDGPU libdrm fallback mapping
if(NOT EXISTS "/usr/include/libdrm")
    # Redirect CMake to look at our local fake directory instead of the system folder
    get_filename_component(/usr/include/libdrm "${FAKE_LIBDRM_DIR}" ABSOLUTE)
endif()

EOF

cat "$TORCH_CONFIG_FILE" >> "${TORCH_CONFIG_FILE}.tmp"
mv "${TORCH_CONFIG_FILE}.tmp" "$TORCH_CONFIG_FILE"

git clone https://github.com/vllm-project/vllm.git
cd vllm
git checkout v0.30.0
##uv pip install -e .

# Remove Mooncake dependency from vLLM
grep -vi mooncake requirements/rocm.txt > requirements/rocm-no-mooncake.txt
uv pip install -r requirements/rocm-no-mooncake.txt
uv pip install -e . --no-deps
cd -


##uv pip install "ray[cgraph]"
##uv pip install "vllm[bench]" --extra-index-url https://wheels.vllm.ai/rocm/




# ------------------------------------------------------------
# Final verification
# ------------------------------------------------------------

python - <<'PY'
import torch
import vllm
print()
print("========================================")
print("vLLM installation")
print("========================================")
print("vLLM  :", vllm.__version__)
print("torch :", torch.__version__)
print("HIP   :", torch.version.hip)
print("CUDA  :", torch.version.cuda)
print("========================================")
PY

deactivate
echo "vLLM successfully installed under $INSTALL_DIR"
