# Agents
Tools to work with AI agents

## Description
- `agent_client_server`: split an agent's client from its server into separate Docker containers and connect to a remote LLM
- `agent_security_tests`: run security tests on an agent and/or its environment and log the results
- `http_tests`: HTTP client/server communication tests
- `open_ssh_tunnel_vllm.sh`: open an SSH tunnel to a remote compute node running [vLLM](https://vllm.ai)
- `cluster_api`: [FastAPI](https://fastapi.tiangolo.com)-based web dashboard providing a basic interface to a remote HPC cluster. The following main endpoints are exposed:
  - [#TODO] `cluster-docs`: cluster user guide
  - [#TODO] `viz`: remote data visuzlization portal
  - `ai-chat`: chat with a remote vLLM instance [FastAPI](https://fastapi.tiangolo.com).
  **TODO:** add an AI agent endpoint
