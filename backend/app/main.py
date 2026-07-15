from fastapi import FastAPI

from .database import engine, Base
from . import models
from .routes.inventory import router

Base.metadata.create_all(bind=engine)

app = FastAPI(title="Fridge2Table API")

app.include_router(router)


@app.get("/")
def root():
    return {"message": "F2T Backend Running"}