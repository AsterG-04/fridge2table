from datetime import datetime, timezone

from sqlalchemy import Column, Integer, String, Float, DateTime
from .database import Base


def _utcnow():
    return datetime.now(timezone.utc)


class Ingredient(Base):
    __tablename__ = "ingredients"

    id = Column(Integer, primary_key=True, index=True)

    name = Column(String, nullable=False)

    quantity = Column(Float, nullable=False)

    unit = Column(String, nullable=False)

    expiry_date = Column(String)

    category = Column(String)

    location = Column(String)

    updated_at = Column(
        DateTime(timezone=True),
        nullable=False,
        default=_utcnow,
        onupdate=_utcnow,
    )