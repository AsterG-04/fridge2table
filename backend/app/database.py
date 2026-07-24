import os

from dotenv import load_dotenv
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base

load_dotenv()

# DATABASE_URL is set in production (Render) to a Supabase Postgres
# connection string, since a free-tier web service's local disk is wiped on
# every idle-restart -- SQLite would lose all pantry data every time the
# service sleeps. Local dev has no DATABASE_URL set, so it keeps using the
# SQLite file for a zero-setup dev loop.
DATABASE_URL = os.environ.get("DATABASE_URL", "sqlite:///./fridge2table.db")

connect_args = {"check_same_thread": False} if DATABASE_URL.startswith("sqlite") else {}

engine = create_engine(
    DATABASE_URL,
    connect_args=connect_args
)

SessionLocal = sessionmaker(
    autocommit=False,
    autoflush=False,
    bind=engine
)

Base = declarative_base()