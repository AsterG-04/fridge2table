from datetime import datetime, timezone

from sqlalchemy import Column, Integer, String, Float, DateTime
from .database import Base


def _utcnow():
    return datetime.now(timezone.utc)


class Ingredient(Base):
    # Deliberately NOT named "ingredients" -- when DATABASE_URL points at
    # Supabase Postgres (production), that name collides with Supabase's
    # own pre-existing "ingredients" table used by the separate cloud-sync
    # feature (lib/services/supabase_service.dart), which has Row-Level
    # Security enabled and an `id` column with no auto-increment default
    # (its sync path always supplies `id` explicitly, so it never needed
    # one). This backend's own create_ingredient() relies on the database
    # generating `id`, and a direct SQLAlchemy connection has no Supabase
    # JWT/session so RLS's `auth.uid()` is always NULL -- between those two
    # mismatches, every insert failed outright (confirmed via Render
    # reproduction: reads returned empty silently through RLS, writes hit
    # `id`'s NOT NULL-no-default constraint). A separate table name sidesteps
    # both issues rather than trying to reconcile two independently-evolved
    # schemas that were never meant to share one table.
    __tablename__ = "pantry_items"

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