def register_and_verify(client, email="a@example.com", password="supersecret1", name="Al"):
    r = client.post("/api/v1/auth/register", json={"email": email, "password": password, "name": name})
    assert r.status_code == 201, r.text
    code = client.captured_emails[-1]["code"]
    r = client.post("/api/v1/auth/verify", json={"email": email, "code": code})
    assert r.status_code == 200, r.text
    return r.json()


def test_register_sends_code_and_requires_verification(client):
    r = client.post("/api/v1/auth/register", json={"email": "x@e.com", "password": "password12", "name": "X"})
    assert r.status_code == 201
    assert len(client.captured_emails) == 1
    assert len(client.captured_emails[0]["code"]) == 6
    # Cannot log in before verifying.
    r = client.post("/api/v1/auth/login", json={"email": "x@e.com", "password": "password12"})
    assert r.status_code == 403


def test_verify_then_login(client):
    data = register_and_verify(client)
    assert data["user"]["email_verified"] is True
    token = data["access_token"]
    assert token
    r = client.post("/api/v1/auth/login", json={"email": "a@example.com", "password": "supersecret1"})
    assert r.status_code == 200
    assert r.json()["access_token"]


def test_wrong_code_rejected(client):
    client.post("/api/v1/auth/register", json={"email": "w@e.com", "password": "password12", "name": "W"})
    r = client.post("/api/v1/auth/verify", json={"email": "w@e.com", "code": "000000"})
    assert r.status_code == 400


def test_duplicate_verified_email_conflicts(client):
    register_and_verify(client, email="dup@e.com")
    r = client.post("/api/v1/auth/register", json={"email": "dup@e.com", "password": "password12", "name": "D"})
    assert r.status_code == 409


def test_short_password_rejected(client):
    r = client.post("/api/v1/auth/register", json={"email": "s@e.com", "password": "short", "name": "S"})
    assert r.status_code == 422


def test_change_password(client):
    data = register_and_verify(client, email="pw@e.com")
    token = data["access_token"]
    h = {"Authorization": f"Bearer {token}"}
    r = client.post("/api/v1/me/password", json={"current_password": "supersecret1", "new_password": "newsecret99"}, headers=h)
    assert r.status_code == 204
    assert client.post("/api/v1/auth/login", json={"email": "pw@e.com", "password": "supersecret1"}).status_code == 401
    assert client.post("/api/v1/auth/login", json={"email": "pw@e.com", "password": "newsecret99"}).status_code == 200


def test_update_settings(client):
    data = register_and_verify(client, email="set@e.com")
    h = {"Authorization": f"Bearer {data['access_token']}"}
    r = client.patch("/api/v1/me", json={"timezone": "America/Sao_Paulo", "language": "pt", "name": "Viny"}, headers=h)
    assert r.status_code == 200
    body = r.json()
    assert body["timezone"] == "America/Sao_Paulo"
    assert body["language"] == "pt"
    assert body["name"] == "Viny"
