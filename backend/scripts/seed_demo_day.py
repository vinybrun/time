"""Seed a realistic full day of entries for a user, for demos/proofs.

Registers+verifies the user if needed (requires EXPOSE_CODES=true on the target
backend for the dev-code shortcut), then upserts a believable 24h schedule.

Usage:
  python -m scripts.seed_demo_day --base http://localhost:8799 \
      --email demo@time.test --password password123 --name Demo --day 2026-06-24
"""
import argparse
import sys
import urllib.request
import json
from datetime import date, timedelta

# (category, start_min, end_min) — a full, balanced day.
SCHEDULE = [
    ("sleep", 0, 450),
    ("self_maintenance", 450, 510),
    ("work", 510, 720),
    ("leisure", 720, 780),
    ("work", 780, 1020),
    ("personal_chores", 1020, 1080),
    ("relationships", 1080, 1170),
    ("growth", 1170, 1260),
    ("personal_projects", 1260, 1380),
    ("sleep", 1380, 1440),
]


def _post(url, payload, token=None):
    data = json.dumps(payload).encode()
    req = urllib.request.Request(url, data=data, method="POST")
    req.add_header("Content-Type", "application/json")
    if token:
        req.add_header("Authorization", f"Bearer {token}")
    with urllib.request.urlopen(req) as r:
        return json.loads(r.read() or "{}")


def _get(url):
    with urllib.request.urlopen(url) as r:
        return json.loads(r.read() or "{}")


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--base", required=True)
    p.add_argument("--email", required=True)
    p.add_argument("--password", default="password123")
    p.add_argument("--name", default="Demo")
    p.add_argument("--day", default=str(date.today() - timedelta(days=1)))
    args = p.parse_args()
    b = args.base.rstrip("/") + "/api/v1"

    # Register (ignore conflict) then verify via dev-code.
    try:
        _post(f"{b}/auth/register", {"email": args.email, "password": args.password, "name": args.name})
    except Exception:
        pass
    code = _get(f"{b}/auth/dev-code?email={args.email}")["code"]
    tok = _post(f"{b}/auth/verify", {"email": args.email, "code": code})["access_token"]

    upserts = [
        {"client_id": f"seed-{args.day}-{i}", "day": args.day, "category": c,
         "start_min": s, "end_min": e}
        for i, (c, s, e) in enumerate(SCHEDULE)
    ]
    res = _post(f"{b}/entries/sync", {"upserts": upserts, "deletes": []}, tok)
    print(f"Seeded {len(SCHEDULE)} entries for {args.email} on {args.day}; "
          f"backend now holds {len(res)} entries.")


if __name__ == "__main__":
    main()
