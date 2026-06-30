# Agents
Tools to work with AI agents

## Description
For now, this repo contains code to:
1. Create two separate Docker containers running the OpenAI Codex app server and client, respectively.
2. Set up an SSH tunnel from the client to the server.
3. Set up an SSH tunnel from the server to a remote machine running vLLM.


## TODOs
1. Include more AI agents (e.g., Claude Code, OpenCode, Mistral Vibe, Qwen Code, ...)
2. [...]


## Instructions
These instructions assume you have Docker installed on your machine. If you don't, check out the [official instructions](https://docs.docker.com/get-started/get-docker) on how to get Docker.

Once Docker is installed, follow these steps:

1. Set up an SSH tunnel from this computer to the remote compute node running vLLM:
   ```
   export VLLM_API_KEY=my-vllm-api-key  # NOTE: use the actual key!
   ./Open_vLLM_tunnel_vLLM.sh user@hostname remote-node 8000 8000 my-vllm-key
   ```

2. Build the Docker images for the Codex app server (see `Codex/Server/Dockerfile.codex.server`) and client (see `Codex/Client/Dockerfile.codex.client`):
   ```
   docker build --pull --no-cache -f Codex/Client/Dockerfile.codex.client -t codex-client:latest .
   docker build --pull --no-cache -f Codex/Server/Dockerfile.codex.server -t codex-server:latest .
   ```
   Notes:
   - The `--pull` flag pulls a fresh Ubuntu base image on every rebuild (see [here](https://docs.docker.com/build/building/best-practices/#use---pull-to-get-fresh-base-images)).
   - The `--no-cache` flag disables the build cache and forces Docker to rebuild all image layers from scratch (see [here](https://docs.docker.com/build/building/best-practices/#use---no-cache-for-clean-builds)).
   - Docker image names must be lowercase.

3. Create a network for the two containers:
   ```
   docker network create codex-network
   ```

4. Start the two containers:
   ```
   docker run -dit --name client --network codex-network codex-client:latest bash
   docker run -dit --name server --network codex-network --add-host host.docker.internal=host-gateway codex-server:latest bash
   ```
   Notes:
   - `-d`: detach from container
   - `-i`: run container command (`bash`) interactively
   - `-t`: set up a pseudo-TTY (essentially, a terminal)
   - `host-gateway` resolves to the internal IP address of the host machine
   - It is conventional to use `host.docker.internal` as the hostname referring to `host-gateway`. Further info [here](https://docs.docker.com/reference/cli/docker/container/run/#add-host).

5. Generate the client's SSH key pair:
   ```
   docker exec -u codex-client-user client bash -c "ssh-keygen -t ed25519 -f /home/codex-client-user/.ssh/id_ed25519 -N ''"
   ```

6. Start `sshd` on the server:
   ```
   docker exec -u root server bash -c "ssh-keygen -A && /usr/sbin/sshd"
   ```

7. Copy the client's public key into the server's `authorized_keys`:
   ```
   docker exec -u codex-client-user client cat /home/codex-client-user/.ssh/id_ed25519.pub | docker exec -u codex-server-user -i server bash -c "cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"
   ```

8. Verify the SSH connection between the client and server containers works:
   ```
   docker exec -u codex-client-user -it client bash -c "ssh -o StrictHostKeyChecking=accept-new codex-server-user@server echo ok"
   ```

9. Open an SSH tunnel between the client and server containers and check it's actually open:
   ```
   docker exec -u codex-client-user -d client bash -c "ssh -fNT -o ExitOnForwardFailure=yes -L 4500:127.0.0.1:4500 codex-server-user@server"
   docker exec -u codex-client-user client bash -c "ss -tlnp | grep 4500"
   ```

10. Launch the Codex app server (in the background):
    ```
    docker attach server
    # Now you are inside the server container
    export VLLM_API_KEY=my-vllm-api-key  # NOTE: use the actual key!
    mkdir -p ~/Codex_projects/Codex_server && cd ~/Codex_projects/Codex_server
    codex app-server --listen ws://127.0.0.1:4500 > codex-app-server.log 2>&1 &
    ```

11. In a separate terminal, launch the Codex client:
    ```
    docker attach client
    # Now you are inside the client container
    mkdir -p ~/Codex_projects/Codex_client && cd ~/Codex_projects/Codex_client
    codex --remote ws://127.0.0.1:4500 --cd /home/codex-server-user/Codex_projects/Codex_server
    ```
    **NOTE:** passing `--cd /home/codex-server-user/Codex_projects/Codex_server` to `codex --remote [...]` lets the Codex client know explicitly that the working directory is the remote one (i.e., the one in the server container) and avoids confusion between the actual working directory and the directory the Codex client was launched from.


## Gotchas
- Container's filesystem access and action approval policy
  - **Client**
    - Read-only permissions on the directory the client was launched from. However, this is irrelevant because this directory can't be accessed by the agent running on the server side: the SSH tunnel runs from the client to the agent, not viceversa.
    - Strict action approval policy. Again, this is irrelevant for the same reason as above.
  - **Server**
    - Full-access sandbox mode: *potential* read/write permissions on the entire server container, although no actions requiring root privileges can be taken *so long as the Codex app server is run by a non-root user*. We may consider restricting the sandbox setting to read/write permissions in the workspace (current working directory plus `/tmp`) only.
    - Lenient action approval policy

- Working sessions are saved on the server side

- You can detach from a running Docker container without stopping it with `ctrl+P ctrl+Q`
