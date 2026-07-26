# ==============================================================================
# This script is meant to be run via FastAPI (by e.g. executing `fastapi dev` in
# a terminal). Export the needed environment variables before launching FastAPI
# (see install.sh). The script exposes a few endpoints:
# ***** Main pages (accessible through the dashboard) *****
# - /             (GET):  root endpoint, loads homepage.html
# - /cluster-docs (GET):  cluster documentation
# - /viz          (GET):  remote data visualization service
# - /ai-chat      (POST): chat with a remote vLLM instance
# ***** Other pages *****
# - /vllm-health  (GET):  vLLM status
# - /vllm-models  (GET):  list of available vLLM models
# ***** #TODO *****
# - /ai-agent     (POST): hit a remote AI agent using that vLLM instance as its backend engine
# ==============================================================================
import os
from fastapi import FastAPI
import httpx
from fastapi.responses import FileResponse
from pydantic import BaseModel
##from openai import OpenAI
from openai import AsyncOpenAI

# -----------------------
# Prepare the environment
# -----------------------
app = FastAPI()

# Pydantic-compatible class representing a chat request
# TODO: implement other request features if needed
class ChatRequest(BaseModel):
    prompt: str 

# Capture the needed environment variables
try:
    dashboard = os.environ["DASHBOARD"]
except KeyError:
    print("Environment variable DASHBOARD is not defined")

try:
    cluster_docs = os.environ["CLUSTER_DOCS"]
except KeyError:
    print("Environment variable CLUSTER_DOCS is not defined")

try:
    viz = os.environ["VIZ"]
except KeyError:
    print("Environment variable VIZ is not defined")

try:
    ai_chat = os.environ["AI_CHAT"]
except KeyError:
    print("Environment variable AI_CHAT is not defined")

try:
    model = os.environ["MODEL_NAME"]
except KeyError:
    print("Environment variable MODEL_NAME is not defined")


# ***** OpenAI-compatible vLLM endpoint *****
try:
    vllm_port       = os.environ["VLLM_PORT"]
    vllm_url        = f"http://127.0.0.1:{vllm_port}"
    vllm_openai_url = vllm_url + "/v1"
except KeyError:
    print("Environment variable VLLM_PORT is not defined")

try:
    vllm_api_key = os.environ["VLLM_API_KEY"]
except KeyError:
    print("Environment variable VLLM_API_KEY is not defined")

##client = OpenAI(
client = AsyncOpenAI(
    base_url = vllm_openai_url,
    api_key  = vllm_api_key
)


# ---------
# Dashboard
# ---------
@app.get("/")
async def serve_dashboard():
    return FileResponse(dashboard)


# ------------------
# Cluster user guide
# ------------------
@app.get("/cluster-docs")
async def serve_cluster_docs():
    return FileResponse(cluster_docs)


# ---------------------------------
# Remote data visualization service
# ---------------------------------
# XXX: this should probably become a GET+POST method
@app.get("/viz")
async def serve_viz():
    return FileResponse(viz)


# ---------------
# AI chat service
# ---------------
@app.get("/ai-chat")
async def serve_ai_chat():
    return FileResponse(ai_chat)


@app.post("/send_prompt")
async def send_prompt(req: ChatRequest):
    ##response = f"Mock response (your prompt):\n{req.prompt}"
    ##completion = client.chat.completions.create(
    completion = await client.chat.completions.create(
        model = model,
        messages = [{
            "role": "user",
            "content": req.prompt
        }]
    )

    response = (completion.choices[0].message.content)
    return {"response": response}


@app.get("/vllm-health")
async def get_vllm_health():
    vllm_health = httpx.get(vllm_url + "/vllm-health")

    if vllm_health.status_code == 200:
        return {"vllm_health_status": "ok"}
    else:
        return {"vllm_health_status": f"Issue on the vLLM server detected (HTTP error code: {vllm_health.status_code})"}


@app.get("/vllm-models")
async def get_vllm_models():
    models_list = await client.models.list()
    ##return {"first model": models_list.data[0].id}
    return {"models": [model.id for model in models_list.data]}


# TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO
# TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO
# TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO
##@app.post("/ai-agent")
##async def post_agent(req: ChatRequest):
##    # XXX: placeholder for now, return actual LLM response
##    response = f"Mock response (your prompt):\n{req.prompt}"
##
##    return {"response": response}
# TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO
# TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO
# TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO
