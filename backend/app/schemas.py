from datetime import datetime, timezone

from pydantic import BaseModel, field_validator


class IngredientCreate(BaseModel):
    name: str
    quantity: float
    unit: str
    expiry_date: str | None = None
    category: str | None = None
    location: str | None = None


class IngredientResponse(IngredientCreate):
    id: int
    updated_at: datetime

    # SQLite doesn't reliably round-trip timezone-aware datetimes, so a
    # value read back naive is normalized to UTC here (it was always
    # written as UTC by the model's default/onupdate). Without this, the
    # API would inconsistently emit some timestamps with a UTC offset and
    # some without, breaking any "newest updated_at wins" comparison.
    @field_validator("updated_at", mode="before")
    @classmethod
    def _ensure_utc(cls, value):
        if isinstance(value, datetime) and value.tzinfo is None:
            return value.replace(tzinfo=timezone.utc)
        return value

    class Config:
        from_attributes = True