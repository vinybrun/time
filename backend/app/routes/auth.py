import logging
from datetime import datetime, timedelta, timezone

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from ..config import get_settings
from ..db import get_db
from ..email_util import send_verification_email
from ..models import User, VerificationCode
from ..schemas import (
    LoginIn,
    RegisterIn,
    ResendIn,
    TokenOut,
    UserOut,
    VerifyIn,
)
from ..security import (
    create_access_token,
    generate_code,
    hash_code,
    hash_password,
    verify_code,
    verify_password,
)

router = APIRouter(prefix="/auth", tags=["auth"])
settings = get_settings()
log = logging.getLogger("time.auth")


def _normalize_email(email: str) -> str:
    return email.strip().lower()


def _issue_code(db: Session, user: User) -> str:
    """Invalidate old codes, create a fresh one, and email it. Returns the code."""
    db.query(VerificationCode).filter(
        VerificationCode.user_id == user.id,
        VerificationCode.purpose == "verify_email",
        VerificationCode.used == False,  # noqa: E712
    ).update({"used": True})
    code = generate_code()
    vc = VerificationCode(
        user_id=user.id,
        code_hash=hash_code(code),
        purpose="verify_email",
        expires_at=datetime.now(timezone.utc)
        + timedelta(minutes=settings.code_ttl_minutes),
    )
    db.add(vc)
    db.commit()
    try:
        send_verification_email(user.email, user.name, code)
    except Exception as exc:  # email failure shouldn't 500 registration
        log.error("Failed to send verification email to %s: %s", user.email, exc)
    return code


def _maybe_expose(code: str) -> dict:
    """Include the code in the response only in local-dev mode."""
    return {"dev_code": code} if settings.expose_codes else {}


@router.post("/register", status_code=status.HTTP_201_CREATED)
def register(payload: RegisterIn, db: Session = Depends(get_db)) -> dict:
    email = _normalize_email(payload.email)
    existing = db.scalar(select(User).where(User.email == email))
    if existing is not None:
        if existing.email_verified:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="An account with this email already exists.",
            )
        # Unverified: refresh password/name and re-send code (idempotent re-register).
        existing.password_hash = hash_password(payload.password)
        existing.name = payload.name or existing.name
        db.commit()
        code = _issue_code(db, existing)
        return {"status": "verification_sent", "email": email, **_maybe_expose(code)}

    user = User(
        email=email,
        name=payload.name,
        password_hash=hash_password(payload.password),
        email_verified=False,
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    code = _issue_code(db, user)
    return {"status": "verification_sent", "email": email, **_maybe_expose(code)}


@router.post("/resend")
def resend(payload: ResendIn, db: Session = Depends(get_db)) -> dict:
    email = _normalize_email(payload.email)
    user = db.scalar(select(User).where(User.email == email))
    # Always return the same response to avoid leaking which emails exist.
    code = ""
    if user is not None and not user.email_verified:
        code = _issue_code(db, user)
    return {"status": "verification_sent", "email": email, **_maybe_expose(code)}


@router.get("/dev-code")
def dev_code(email: str, db: Session = Depends(get_db)) -> dict:
    """Local-dev only: return the latest unused code for an email so automated
    E2E tests can complete verification. Disabled unless EXPOSE_CODES=true."""
    if not settings.expose_codes:
        raise HTTPException(status_code=404, detail="Not found")
    user = db.scalar(select(User).where(User.email == _normalize_email(email)))
    if user is None:
        raise HTTPException(status_code=404, detail="Not found")
    # We only store hashes; re-issue a fresh known code for the test harness.
    code = _issue_code(db, user)
    return {"code": code}


@router.post("/verify", response_model=TokenOut)
def verify(payload: VerifyIn, db: Session = Depends(get_db)) -> TokenOut:
    email = _normalize_email(payload.email)
    user = db.scalar(select(User).where(User.email == email))
    if user is None:
        raise HTTPException(status_code=400, detail="Invalid code")

    vc = db.scalar(
        select(VerificationCode)
        .where(
            VerificationCode.user_id == user.id,
            VerificationCode.purpose == "verify_email",
            VerificationCode.used == False,  # noqa: E712
        )
        .order_by(VerificationCode.id.desc())
    )
    if vc is None:
        raise HTTPException(status_code=400, detail="Invalid code")
    expires = vc.expires_at
    if expires.tzinfo is None:
        expires = expires.replace(tzinfo=timezone.utc)
    if expires < datetime.now(timezone.utc):
        raise HTTPException(status_code=400, detail="Code expired")
    if not verify_code(payload.code, vc.code_hash):
        raise HTTPException(status_code=400, detail="Invalid code")

    vc.used = True
    user.email_verified = True
    db.commit()
    db.refresh(user)
    return TokenOut(access_token=create_access_token(user.id), user=UserOut.model_validate(user))


@router.post("/login", response_model=TokenOut)
def login(payload: LoginIn, db: Session = Depends(get_db)) -> TokenOut:
    email = _normalize_email(payload.email)
    user = db.scalar(select(User).where(User.email == email))
    if user is None or not verify_password(payload.password, user.password_hash):
        raise HTTPException(status_code=401, detail="Invalid email or password")
    if not user.email_verified:
        # Re-issue a code so the client can route to the verify screen.
        _issue_code(db, user)
        raise HTTPException(status_code=403, detail="Email not verified")
    return TokenOut(access_token=create_access_token(user.id), user=UserOut.model_validate(user))
