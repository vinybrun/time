from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import select
from sqlalchemy.orm import Session

from ..db import get_db
from ..deps import get_verified_user
from ..models import TimeEntry, User
from ..schemas import EntryIn, EntryOut, SyncIn

router = APIRouter(prefix="/entries", tags=["entries"])


def _upsert(db: Session, user: User, payload: EntryIn) -> TimeEntry:
    entry = db.scalar(
        select(TimeEntry).where(
            TimeEntry.user_id == user.id, TimeEntry.client_id == payload.client_id
        )
    )
    if entry is None:
        entry = TimeEntry(user_id=user.id, client_id=payload.client_id)
        db.add(entry)
    entry.day = payload.day
    entry.category = payload.category
    entry.start_min = payload.start_min
    entry.end_min = payload.end_min
    return entry


@router.get("", response_model=list[EntryOut])
def list_entries(
    day: str | None = Query(default=None, pattern=r"^\d{4}-\d{2}-\d{2}$"),
    since: str | None = Query(default=None, description="ISO8601 updated_at lower bound"),
    db: Session = Depends(get_db),
    user: User = Depends(get_verified_user),
) -> list[TimeEntry]:
    stmt = select(TimeEntry).where(TimeEntry.user_id == user.id)
    if day is not None:
        stmt = stmt.where(TimeEntry.day == day)
    stmt = stmt.order_by(TimeEntry.day, TimeEntry.start_min)
    return list(db.scalars(stmt))


@router.post("", response_model=EntryOut)
def create_or_update_entry(
    payload: EntryIn,
    db: Session = Depends(get_db),
    user: User = Depends(get_verified_user),
) -> TimeEntry:
    entry = _upsert(db, user, payload)
    db.commit()
    db.refresh(entry)
    return entry


@router.delete("/{client_id}", status_code=204)
def delete_entry(
    client_id: str,
    db: Session = Depends(get_db),
    user: User = Depends(get_verified_user),
) -> None:
    entry = db.scalar(
        select(TimeEntry).where(
            TimeEntry.user_id == user.id, TimeEntry.client_id == client_id
        )
    )
    if entry is None:
        raise HTTPException(status_code=404, detail="Not found")
    db.delete(entry)
    db.commit()


@router.post("/sync", response_model=list[EntryOut])
def sync(
    payload: SyncIn,
    db: Session = Depends(get_db),
    user: User = Depends(get_verified_user),
) -> list[TimeEntry]:
    """Idempotent bulk upsert + delete, returns the user's full entry set."""
    for item in payload.upserts:
        _upsert(db, user, item)
    if payload.deletes:
        db.query(TimeEntry).filter(
            TimeEntry.user_id == user.id,
            TimeEntry.client_id.in_(payload.deletes),
        ).delete(synchronize_session=False)
    db.commit()
    return list(
        db.scalars(
            select(TimeEntry)
            .where(TimeEntry.user_id == user.id)
            .order_by(TimeEntry.day, TimeEntry.start_min)
        )
    )
