from enum import Enum
from pydantic import BaseModel  # Needed to validate HTTP POST requests
from fastapi import FastAPI

# Basic FastAPI object
app = FastAPI()


# ================
# HTTP GET methods
# ================
# ------------------------------------------------------------------------------
# Handle HTTP "GET" requests on path (endpoint) "/"
# Notes:
# - @app.get("/") is a function decorator
# - The function is declared async to boost performance, but that's not strictly
#   required
# - The function name can be anything
# - This function returns a Python dictionary, but the return type can be nearly
#   anything
# - To test the function, you can e.g. open a web browser and navigate to
#   https://localhost:8000
# ------------------------------------------------------------------------------
@app.get("/")
async def get_root():
    return {"message": "Hello from the root endpoint"}

# Test this function by e.g. opening a web browser and navigating to
# https://localhost:8000/items/ints/57
# (any other integer will do)
@app.get("/items/ints/{item}")
async def get_item(item: int):
    return {"Integer item": item}

# Test this function by e.g. opening a web browser and navigating to
# https://localhost:8000/items/strings/Any string I like
# (any other string will do)
@app.get("/items/strings/{item}")
async def get_item(item: str):
    return {"String item": item}


# ------------------------------------------------------------------------------
# Handle the choice among multiple options via an enum class, which nicely shows
# up as a drop-down menu under https://localhost:8000/docs
# ------------------------------------------------------------------------------
class Option(str, Enum):
    option1 = "Option 1"
    option2 = "Option 2"
    option3 = "Option 3"

@app.get("/options/{option}")
async def get_option(option: Option):
    if option is Option.option1:
    # or: if option.value == "Option 1"
        return {
                "option": option,
                "message": "Option 1 selected"
               }
    if option is Option.option2:
    # or: if option.value == "Option 2"
        return {
                "option": option,
                "message": "Option 2 selected"
               }
    if option is Option.option3:
    # or: if option.value == "Option 3"
        return {
                "option": option,
                "message": "Option 3 selected"
               }
    else:
        return {
                "option": option,
                "message": "Invalid option {option} selected"
               }


# -----------------------------------------------------------------------------
# Handle query parameters, i.e., any function parameter that is not a path
# listed in the function's decorator
# NOTE: `str | None = None` means the parameter can either be of string or None
#       type and defaults to being None
# -----------------------------------------------------------------------------
@app.get("/items/{item_id}")
async def read_item(item_id: str, optional: str | None = None):
    if optional:
        return {
                "item_id": item_id,
                "optional": optional
               }
    else:
        return {"item_id": item_id}



# =================
# HTTP POST methods
# =================

# Example Pydantic data model class representing a car. Inherits from Pydantic's
# BaseModel class.
class Car(BaseModel):
    # Required parameters
    brand: str
    model: str
    price: float
    # Optional parameters
    description: str | None = None
    engine: str | None = None
    tax: float | None = None

# Handle an HTTP POST request creating an object of Car
@app.post("/cars/")
async def create_car(car: Car):
    # Extract the car's parameters as a Python dictionary
    car_dict = car.model_dump()

    if car.tax is not None:
        car_dict.update({"full_price": car.price + car.tax})

    return car_dict

    # Basic version (commented out)
    ##return car
