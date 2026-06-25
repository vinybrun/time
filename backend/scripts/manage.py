"""Tiny admin CLI for the Time backend.

Usage (from backend/, with the venv active and .env present):
  python -m scripts.manage create-user --email a@b.com --name Viny --password 'secret' [--verified]
  python -m scripts.manage set-password --email a@b.com --password 'newsecret'
  python -m scripts.manage verify --email a@b.com
  python -m scripts.manage list-users
"""
import argparse
import sys

from sqlalchemy import select

from app.db import SessionLocal, init_db
from app.models import User
from app.security import hash_password


def _get(db, email):
    return db.scalar(select(User).where(User.email == email.strip().lower()))


def create_user(args):
    init_db()
    db = SessionLocal()
    email = args.email.strip().lower()
    if _get(db, email):
        print(f"User {email} already exists", file=sys.stderr)
        return 1
    user = User(
        email=email,
        name=args.name or "",
        password_hash=hash_password(args.password),
        email_verified=bool(args.verified),
        timezone=args.timezone,
        language=args.language,
    )
    db.add(user)
    db.commit()
    print(f"Created user {email} (verified={user.email_verified})")
    return 0


def set_password(args):
    db = SessionLocal()
    user = _get(db, args.email)
    if not user:
        print("No such user", file=sys.stderr)
        return 1
    user.password_hash = hash_password(args.password)
    db.commit()
    print(f"Password updated for {user.email}")
    return 0


def verify(args):
    db = SessionLocal()
    user = _get(db, args.email)
    if not user:
        print("No such user", file=sys.stderr)
        return 1
    user.email_verified = True
    db.commit()
    print(f"{user.email} marked verified")
    return 0


def list_users(args):
    db = SessionLocal()
    for u in db.scalars(select(User).order_by(User.id)):
        print(f"#{u.id}  {u.email:32}  verified={u.email_verified}  tz={u.timezone}  lang={u.language}  name={u.name!r}")
    return 0


def main():
    p = argparse.ArgumentParser()
    sub = p.add_subparsers(dest="cmd", required=True)

    c = sub.add_parser("create-user")
    c.add_argument("--email", required=True)
    c.add_argument("--name", default="")
    c.add_argument("--password", required=True)
    c.add_argument("--timezone", default="UTC")
    c.add_argument("--language", default="en")
    c.add_argument("--verified", action="store_true")
    c.set_defaults(func=create_user)

    c = sub.add_parser("set-password")
    c.add_argument("--email", required=True)
    c.add_argument("--password", required=True)
    c.set_defaults(func=set_password)

    c = sub.add_parser("verify")
    c.add_argument("--email", required=True)
    c.set_defaults(func=verify)

    c = sub.add_parser("list-users")
    c.set_defaults(func=list_users)

    args = p.parse_args()
    sys.exit(args.func(args))


if __name__ == "__main__":
    main()
