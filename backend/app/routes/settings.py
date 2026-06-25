from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from ..db import get_db
from ..deps import get_current_user
from ..models import User
from ..schemas import PasswordChangeIn, SettingsIn, UserOut
from ..security import hash_password, verify_password

router = APIRouter(prefix="/me", tags=["me"])


@router.get("", response_model=UserOut)
def get_me(user: User = Depends(get_current_user)) -> User:
    return user


@router.patch("", response_model=UserOut)
def update_me(
    payload: SettingsIn,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
) -> User:
    if payload.name is not None:
        user.name = payload.name
    if payload.timezone is not None:
        user.timezone = payload.timezone
    if payload.language is not None:
        user.language = payload.language
    db.commit()
    db.refresh(user)
    return user


@router.post("/password", status_code=204)
def change_password(
    payload: PasswordChangeIn,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
) -> None:
    if not verify_password(payload.current_password, user.password_hash):
        raise HTTPException(status_code=400, detail="Current password is incorrect")
    user.password_hash = hash_password(payload.new_password)
    db.commit()
