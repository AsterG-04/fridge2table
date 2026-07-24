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

    # The Supabase user this ingredient belongs to. Nullable only so rows
    # created before per-user scoping was added don't break — those legacy
    # rows are treated as orphaned (see migrate_add_user_id.py) and are
    # never returned to any user, since there's no reliable way to know
    # which account they originally belonged to.
    user_id = Column(String, nullable=True, index=True)

    updated_at = Column(
        DateTime(timezone=True),
        nullable=False,
        default=_utcnow,
        onupdate=_utcnow,
    )