import os

os.environ.setdefault("DATABASE_URL", "sqlite:///:memory:")
os.environ.setdefault("JWT_SECRET", "test-secret")

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

import app.db as db_module
from app.db import Base, get_db


@pytest.fixture
def captured_emails(monkeypatch):
    """Capture verification codes instead of sending SMTP."""
    sent = []

    def fake_send(to_addr, name, code):
        sent.append({"to": to_addr, "name": name, "code": code})

    monkeypatch.setattr("app.routes.auth.send_verification_email", fake_send)
    return sent


@pytest.fixture
def client(captured_emails):
    engine = create_engine(
        "sqlite://",
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )
    TestingSession = sessionmaker(bind=engine, autoflush=False, autocommit=False)
    Base.metadata.create_all(bind=engine)

    # Point the app at this in-memory DB.
    monkey_engine = db_module.engine
    db_module.engine = engine
    db_module.SessionLocal = TestingSession

    from app.main import app

    def override_get_db():
        s = TestingSession()
        try:
            yield s
        finally:
            s.close()

    app.dependency_overrides[get_db] = override_get_db
    with TestClient(app) as c:
        c.captured_emails = captured_emails
        yield c
    app.dependency_overrides.clear()
    db_module.engine = monkey_engine
