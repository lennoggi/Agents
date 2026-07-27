# HPC cluster portal

## Description

This is a minimal, [FastAPI](https://fastapi.tiangolo.com)-based web portal to an HPC cluster. From the portal's dashboard, you can access the following cluster services:
- **[Work in progress]** The cluster user guide
- **[Work in progress]** A remote visualization portal
- An AI chat backed by a [vLLM](https://vllm.ai) instance running on the cluster

**NOTE:** accessing the portal currently requires opening an SSH tunnel to the compute node running vLLM (see the instructions below).


## Instructions

1. Open an SSH tunnel from your local machine to the remote node running vLLM, for example:
   ```
   cd ..
   ./open_ssh_tunnel_vllm.sh user@hostname remote-node 8080 8000 my-vllm-key
   cd -
   ```
   See `../open_ssh_tunnel_vllm.sh` for further details.

   Notes:
   - Avoid local port 8000 as that's the port used by default by FastAPI
   - Make sure the remote port (8000 in the example above) really is the port on the remote compute node vLLM is listening to

2. Run
   ```
   . setenv.sh
   ```
   This will:
   a. Create a virtual Python environment
   b. Activate the environment
   c. Install FastAPI and other required packages in the environment
   d. Export all the needed environment variables

3. Run FastAPI:
   ```
   fastapi run
   ```
   This will read into `pyproject.toml`, read `api.py`, and start an HTTP server on `localhost:8000`.

   Notes:
   - You can have FastAPI read a custom API file (default is `main.py`) with a custom FastAPI app name (default is `app`) by either:
     a. Passing `my-api-file:my-app` as a command line argument (e.g., `api:app`)
     b. Editing `pyproject.toml`
   - You can override the default host (0.0.0.0) and port (8000) used by FastAPI via command-line arguments, for example:
     ```
     fastapi dev api:app --host 0.0.0.0 --port 8000
     ```

4. Navigate to the dashboard at `http://localhost:8000/` on any web browser and explore all the services. See also `http://localhost:8000/docs` for a list of all available endpoints.

5. Once you are done, deactivate the environment:
   ```
   deactivate
   ```
