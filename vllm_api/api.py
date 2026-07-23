# ==============================================================================
# This script is meant to be run via FastAPI (by e.g. executing `fastapi dev` in
# a terminal). Export the needed environment variables before launching FastAPI
# (see install.sh). The script exposes a few endpoints:
# - /      (GET):  root endpoint, loads
# - /chat  (POST): hit a remote vLLM instance
# - #TODO: /agent (POST): hit a remote AI agent using that vLLM instance as its backend engine
# ==============================================================================

import os
from fastapi import FastAPI
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

# OpenAI-compatible tools needed to talk to vLLM
try:
    vllm_port = os.environ["VLLM_PORT"]
except KeyError:
    print("Environment variable VLLM_PORT is not defined")

try:
    vllm_api_key = os.environ["VLLM_API_KEY"]
except KeyError:
    print("Environment variable VLLM_API_KEY is not defined")

try:
    model = os.environ["MODEL_NAME"]
except KeyError:
    print("Environment variable MODEL_NAME is not defined")

##client = OpenAI(
client = AsyncOpenAI(
    base_url = f"http://127.0.0.1:{vllm_port}/v1",
    api_key  = vllm_api_key
)


# -----------
# GET methods
# -----------
@app.get("/")
async def get_homepage():
    return FileResponse(os.environ["HOMEPAGE"],)

@app.get("/health")
async def get_health():
    return {"status": "ok"}

@app.get("/models")
async def get_models():
    models_list = await client.models.list()
    ##return {"first model": models_list.data[0].id}
    return {"models": [model.id for model in models_list.data]}


# ------------
# POST methods
# ------------
@app.post("/chat")
async def post_chat(req: ChatRequest):
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


# TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO
# TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO
# TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO
##@app.post("/agent")
##async def post_agent(req: ChatRequest):
##    # XXX: placeholder for now, return actual LLM response
##    response = f"Mock response (your prompt):\n{req.prompt}"
##
##    return {"response": response}
# TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO
# TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO
# TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO TODO
