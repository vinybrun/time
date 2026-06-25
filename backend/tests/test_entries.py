from tests.test_auth import register_and_verify


def auth_header(client):
    data = register_and_verify(client, email="entry@e.com")
    return {"Authorization": f"Bearer {data['access_token']}"}


def test_entries_require_auth(client):
    assert client.get("/api/v1/entries").status_code == 401


def test_create_and_list_entry(client):
    h = auth_header(client)
    payload = {"client_id": "c1", "day": "2026-06-25", "category": "work", "start_min": 540, "end_min": 720}
    r = client.post("/api/v1/entries", json=payload, headers=h)
    assert r.status_code == 200, r.text
    r = client.get("/api/v1/entries?day=2026-06-25", headers=h)
    assert r.status_code == 200
    rows = r.json()
    assert len(rows) == 1
    assert rows[0]["category"] == "work"
    assert rows[0]["start_min"] == 540


def test_upsert_is_idempotent_by_client_id(client):
    h = auth_header(client)
    base = {"client_id": "same", "day": "2026-06-25", "category": "sleep", "start_min": 0, "end_min": 480}
    client.post("/api/v1/entries", json=base, headers=h)
    base["category"] = "work"
    base["end_min"] = 500
    client.post("/api/v1/entries", json=base, headers=h)
    rows = client.get("/api/v1/entries?day=2026-06-25", headers=h).json()
    assert len(rows) == 1
    assert rows[0]["category"] == "work"
    assert rows[0]["end_min"] == 500


def test_custom_category_key_allowed(client):
    h = auth_header(client)
    r = client.post("/api/v1/entries", json={"client_id": "c", "day": "2026-06-25", "category": "custom_yoga", "start_min": 0, "end_min": 10}, headers=h)
    assert r.status_code == 200, r.text


def test_invalid_category_key_rejected(client):
    h = auth_header(client)
    r = client.post("/api/v1/entries", json={"client_id": "c", "day": "2026-06-25", "category": "Bad Key!", "start_min": 0, "end_min": 10}, headers=h)
    assert r.status_code == 422


def test_end_before_start_rejected(client):
    h = auth_header(client)
    r = client.post("/api/v1/entries", json={"client_id": "c", "day": "2026-06-25", "category": "work", "start_min": 100, "end_min": 50}, headers=h)
    assert r.status_code == 422


def test_running_entry_null_end(client):
    h = auth_header(client)
    r = client.post("/api/v1/entries", json={"client_id": "run", "day": "2026-06-25", "category": "leisure", "start_min": 600, "end_min": None}, headers=h)
    assert r.status_code == 200
    assert r.json()["end_min"] is None


def test_delete_entry(client):
    h = auth_header(client)
    client.post("/api/v1/entries", json={"client_id": "d1", "day": "2026-06-25", "category": "work", "start_min": 0, "end_min": 60}, headers=h)
    assert client.delete("/api/v1/entries/d1", headers=h).status_code == 204
    assert client.get("/api/v1/entries?day=2026-06-25", headers=h).json() == []


def test_sync_bulk_upsert_and_delete(client):
    h = auth_header(client)
    client.post("/api/v1/entries", json={"client_id": "keep", "day": "2026-06-25", "category": "work", "start_min": 0, "end_min": 60}, headers=h)
    body = {
        "upserts": [
            {"client_id": "a", "day": "2026-06-25", "category": "sleep", "start_min": 0, "end_min": 60},
            {"client_id": "b", "day": "2026-06-25", "category": "growth", "start_min": 60, "end_min": 120},
        ],
        "deletes": ["keep"],
    }
    r = client.post("/api/v1/entries/sync", json=body, headers=h)
    assert r.status_code == 200
    ids = {row["client_id"] for row in r.json()}
    assert ids == {"a", "b"}


def test_user_isolation(client):
    h1 = auth_header(client)
    client.post("/api/v1/entries", json={"client_id": "u1", "day": "2026-06-25", "category": "work", "start_min": 0, "end_min": 60}, headers=h1)
    data2 = register_and_verify(client, email="other@e.com")
    h2 = {"Authorization": f"Bearer {data2['access_token']}"}
    assert client.get("/api/v1/entries", headers=h2).json() == []
