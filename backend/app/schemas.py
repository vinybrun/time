from datetime import datetime

from pydantic import BaseModel, EmailStr, Field, field_validator

from .models import CATEGORIES


# --- Auth -----------------------------------------------------------------

class RegisterIn(BaseModel):
    email: EmailStr
    password: str = Field(min_length=8, max_length=128)
    name: str = Field(default="", max_length=120)


class VerifyIn(BaseModel):
    email: EmailStr
    code: str = Field(min_length=6, max_length=6)


class LoginIn(BaseModel):
    email: EmailStr
    password: str


class ResendIn(BaseModel):
    email: EmailStr


class ForgotPasswordIn(BaseModel):
    email: EmailStr


class ResetPasswordIn(BaseModel):
    email: EmailStr
    code: str = Field(min_length=6, max_length=6)
    new_password: str = Field(min_length=8, max_length=128)


class TokenOut(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: "UserOut"


# --- User -----------------------------------------------------------------

class UserOut(BaseModel):
    id: int
    email: str
    name: str
    email_verified: bool
    timezone: str
    language: str

    model_config = {"from_attributes": True}


class SettingsIn(BaseModel):
    name: str | None = Field(default=None, max_length=120)
    timezone: str | None = Field(default=None, max_length=64)
    language: str | None = Field(default=None, max_length=8)


class PasswordChangeIn(BaseModel):
    current_password: str
    new_password: str = Field(min_length=8, max_length=128)


# --- Entries --------------------------------------------------------------

class EntryIn(BaseModel):
    client_id: str = Field(min_length=1, max_length=64)
    day: str = Field(pattern=r"^\d{4}-\d{2}-\d{2}$")
    category: str
    start_min: int = Field(ge=0, le=1440)
    end_min: int | None = Field(default=None, ge=0, le=1440)

    @field_validator("category")
    @classmethod
    def _valid_category(cls, v: str) -> str:
        if v not in CATEGORIES:
            raise ValueError(f"invalid category: {v}")
        return v

    @field_validator("end_min")
    @classmethod
    def _end_after_start(cls, v: int | None, info) -> int | None:
        start = info.data.get("start_min")
        if v is not None and start is not None and v < start:
            raise ValueError("end_min must be >= start_min")
        return v


class EntryOut(BaseModel):
    id: int
    client_id: str
    day: str
    category: str
    start_min: int
    end_min: int | None
    updated_at: datetime

    model_config = {"from_attributes": True}


class SyncIn(BaseModel):
    """Bulk upsert + delete for offline-first sync."""

    upserts: list[EntryIn] = Field(default_factory=list)
    deletes: list[str] = Field(default_factory=list)  # client_ids


TokenOut.model_rebuild()
