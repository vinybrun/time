# Time

A calm daily time-accountability app. One screen: a hollow 24-hour ring that
shows where your day actually went, split into life areas. Pick your current
focus with a tap, fix history when you forget, and watch each day fill in.

**Live:** https://time.sovereinia.org · Flutter (web + Android) · FastAPI backend.

![Time](proofs/README/hero.png)

## The idea

- The ring is a full day (24h). Each category is an arc sized by the time you
  spent on it; division ticks reach outward with a small label per section.
- Every day starts asleep at 00:00. Tap a category to switch your **current
  focus** — that closes the running segment and opens a new one.
- The header is a scroll of days; each day fills green in proportion to the
  hours you've logged (fully green at 24h).
- You can change history: add entries, or tap any time/category to edit it.

Categories: Work · Personal chores · Personal projects · Leisure ·
Relationships · Self maintenance · Growth · Sleep · Uncategorized.

## Layout

```
backend/   FastAPI + SQLite. Email/password auth with email verification,
           JWT sessions, time-entry CRUD + offline-first sync.
frontend/  Flutter app (web + Android). Riverpod, local-first cache, i18n
           (en, pt, es, fr, de), off-white theme.
deploy/    nginx vhost, systemd unit, direct deploy scripts (no Docker/CI).
```

## Backend (dev)

```bash
cd backend
python3 -m venv .venv && . .venv/bin/activate
pip install -e ".[dev]"
pytest                                   # unit + API tests
# Run with a verification-code shortcut for local UI testing:
EXPOSE_CODES=true uvicorn app.main:app --port 8799
```

Key endpoints (`/api/v1`): `auth/{register,verify,login,resend}`,
`me` (+ `me/password`), `entries` (+ `entries/sync`). Docs at `/docs`.

Verification emails are sent through the host's local SMTP (Postfix) as
`time@alterspring.org`. Passwords are bcrypt-hashed; codes are stored hashed.

## Frontend (dev)

```bash
cd frontend
flutter pub get
flutter test
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8799
```

The app is local-first: it renders from a cached copy instantly and syncs in
the background, so there are no spinners in normal use.

## Deploy (direct, no Docker)

The backend runs under systemd (`uvicorn` on `127.0.0.1:8810`); nginx serves the
static web build and proxies `/api`. Real infra values are passed via env at
invocation and never committed.

```bash
# First time only: create dirs/.env, install unit + vhost, then TLS.
DEPLOY_HOST=user@host DEPLOY_SSH_KEY=~/.ssh/key \
DEPLOY_DIR=/srv/apps/time DEPLOY_DOMAIN=time.sovereinia.org \
./deploy/bootstrap-remote.sh

# Every deploy: build web, rsync web+backend, restart service.
DEPLOY_HOST=user@host DEPLOY_SSH_KEY=~/.ssh/key \
DEPLOY_DIR=/srv/apps/time DEPLOY_DOMAIN=time.sovereinia.org \
./deploy/deploy.sh
```

## License

MIT — made by [Viny](https://github.com/vinybrun).
