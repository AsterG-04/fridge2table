from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from .database import engine, Base
from . import models
from .routes.inventory import router

Base.metadata.create_all(bind=engine)

app = FastAPI(title="Fridge2Table API")

# The app is a native mobile client (no browser origin to restrict), and
# this backend has no cookie-based auth to protect -- every request is
# authenticated via a bearer JWT (see app/auth.py), not cookies/origin.
# Open CORS just avoids friction for anyone hitting this from a browser
# (docs, manual testing).
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(router)


@app.get("/")
def root():
    return {"message": "F2T Backend Running"}