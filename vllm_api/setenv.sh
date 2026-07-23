# This script should be sourced to:
# 1. Create a virtual Python environment
# 2. Activate the environment
# 3. Install FastAPI and other required packages
set -x
python3 -m venv fastapi_venv
. fastapi_venv/bin/activate
pip install -r requirements.txt
export PYTHONDONTWRITEBYTECODE=1  # Avoid writing __pycache__
export HOMEPAGE=$(realpath homepage.html)
export VLLM_PORT=8080                 # XXX: replace with the actual SSH-forwarded port
export VLLM_API_KEY="my-vllm-api-key" # XXX: replace this with your actual vLLM API key
export MODEL_NAME=$(curl http://127.0.0.1:$VLLM_PORT/v1/models -H "Authorization: Bearer $VLLM_API_KEY" | jq -r '.data[].id')
set +x
echo ""
echo "================================================================================"
echo "Homepage file: "$HOMEPAGE""
echo "vLLM port:     $VLLM_PORT"
echo "vLLM URL:      http://127.0.0.1:$VLLM_PORT/v1"
echo "vLLM API key:  "$VLLM_API_KEY""
echo "Model:         "$MODEL_NAME""
echo "================================================================================"
echo ""
echo "NEXT STEP: run"
echo "  fastapi dev"
