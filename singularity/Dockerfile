# =============================================================================
# This Dockerfile adds Ray to an existing vLLM+ROCm image that doesn't ship Ray
# =============================================================================
FROM vllm/vllm-openai-rocm:v0.30.0

# `grep -v ' @ '` cleans up the constraints file by deleting lines like
# amd-aiter @ file:///install/amd_aiter-0.1.21.post2-cp312-cp312-linux_x86_64.whl#sha256=2e5    82e26a7419f124f54ebc7547c26f92ba44bf6f24b21cea8784f28281b3f50
RUN python3 -m pip freeze | grep -v ' @ ' > /tmp/constraints.txt
RUN python3 -m pip install --root-user-action=ignore "ray[default]" -c /tmp/constraints.txt
RUN python3 -m pip check || true
