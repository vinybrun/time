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


def test_forgot_and_reset_password(client):
    register_and_verify(client, email="reset@e.com", password="oldpassword1")
    # Request a reset code (exposed in test mode via captured_emails).
    r = client.post("/api/v1/auth/forgot-password", json={"email": "reset@e.com"})
    assert r.status_code == 200
    code = client.captured_emails[-1]["code"]
    # Reset with the code -> logs in.
    r = client.post("/api/v1/auth/reset-password", json={"email": "reset@e.com", "code": code, "new_password": "brandnew123"})
    assert r.status_code == 200, r.text
    assert r.json()["access_token"]
    # Old password no longer works; new one does.
    assert client.post("/api/v1/auth/login", json={"email": "reset@e.com", "password": "oldpassword1"}).status_code == 401
    assert client.post("/api/v1/auth/login", json={"email": "reset@e.com", "password": "brandnew123"}).status_code == 200


def test_reset_password_wrong_code(client):
    register_and_verify(client, email="reset2@e.com")
    client.post("/api/v1/auth/forgot-password", json={"email": "reset2@e.com"})
    r = client.post("/api/v1/auth/reset-password", json={"email": "reset2@e.com", "code": "000000", "new_password": "brandnew123"})
    assert r.status_code == 400


def test_forgot_password_unknown_email_no_enumeration(client):
    # Returns 200 even for an unknown address, and sends nothing.
    before = len(client.captured_emails)
    r = client.post("/api/v1/auth/forgot-password", json={"email": "nobody@e.com"})
    assert r.status_code == 200
    assert len(client.captured_emails) == before


def test_update_settings(client):
    data = register_and_verify(client, email="set@e.com")
    h = {"Authorization": f"Bearer {data['access_token']}"}
    r = client.patch("/api/v1/me", json={"timezone": "America/Sao_Paulo", "language": "pt", "name": "Viny"}, headers=h)
    assert r.status_code == 200
    body = r.json()
    assert body["timezone"] == "America/Sao_Paulo"
    assert body["language"] == "pt"
    assert body["name"] == "Viny"
