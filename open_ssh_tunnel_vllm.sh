# ==============================================================================
# 1. Open an SSH tunnel from a local port to a specific compute node on a remote
#    endpoint (usually a login node of a remote machine) where vLLM is running
# 2. Get the running model's name. If --api-key was passed to "vllm serve ...",
#    then you need to provide that key
# Example usage:
#   ./open_ssh_tunnel_vllm.sh user@hostname remote-node 8000 8000 my-vllm-key
#
# ***** To close the tunnel *****
# 1. List all network applications that are currently listening to incoming TCP
#    connections:
#      ss -tlnp
# 2. Kill the process owned by user "ssh"
#     kill <pid>
# ==============================================================================
set -euo pipefail

if [ "$#" -lt 5 ]
then
    echo "Usage:"
    echo "  $0 \\"
    echo "    [endpoint]      \\  # e.g., user@hostname"
    echo "    [node]          \\"
    echo "    [local port]    \\  # e.g., 8000"
    echo "    [endpoint port] \\  # e.g., 8000"
    echo "    [vLLM API key]  \\  # Pass, e.g., \"dummy\" if no vLLM key is present"
fi

ENDPOINT=$1
NODE=$2
LOCAL_PORT=$3
ENDPOINT_PORT=$4
VLLM_API_KEY=$5

# 0.0.0.0 (instead of just the localhost 127.0.0.1) means "bind the whole local
# network, not just localhost, to port $LOCAL_PORT". Useful e.g. when connecting
# from a Docker container.
ssh -fNT -o ExitOnForwardFailure=yes -L 0.0.0.0:$LOCAL_PORT:$NODE:$ENDPOINT_PORT $ENDPOINT
MODEL_NAME=$(curl http://127.0.0.1:$LOCAL_PORT/v1/models -H "Authorization: Bearer $VLLM_API_KEY" | jq -r '.data[].id')

echo ""
echo "- Opened SSH tunnel from local port $LOCAL_PORT to compute node $NODE on $ENDPOINT via endpoint port $ENDPOINT_PORT"
echo "- Found model \"$MODEL_NAME\" running on node $NODE, connect to it via http://127.0.0.1:$LOCAL_PORT/v1"
echo "- To close the tunnel, run"
echo "    ss -tlnp"
echo "  and kill the process owned by user \"ssh\""
