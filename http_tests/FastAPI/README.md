# HTTP client/server pair with FastAPI

## Description

This is a basic example of how to set up an HTTP client/server pair using FastAPI.


## Instructions

1. Create a virtual Python environment:
   ```
   python3 -m venv fastapi_venv
   ```

2. Activate the environment:
   ```
   . fastapi_venv/bin/activate
   ```

3. Install FastAPI:
   ```
   pip install fastapi[standard]
   ```

4. Run FastAPI:
   ```
   fastapi dev main:app --host 0.0.0.0 --port 8000
   ```
   This will start an HTTP server on `localhost:8000`.

   **NOTE:** running `fastapi dev` without any other flags will behave exactly as above.

5. Open the main page `http://localhost:8000/` on any web browser. See also `http://localhost:8000/docs` for a list of all available endpoints.

6. Deactivate the environment:
   ```
   deactivate
   ```


## Useful links

- Main web page: [https://fastapi.tiangolo.com](https://fastapi.tiangolo.com)
- Start from [https://fastapi.tiangolo.com/tutorial](https://fastapi.tiangolo.com/tutorial)
