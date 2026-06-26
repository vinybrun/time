---
name: direct-vps-deploy
description: Deploy a web app + API directly to a shared VPS without Docker or CI — nginx vhost, systemd service, certbot TLS behind Cloudflare, env-var-driven deploy scripts, and public-repo secret hygiene. Use when asked to deploy a Flutter-web/FastAPI (or similar static-frontend + API) app to a server over SSH, set up a new subdomain with TLS, or write a repeatable deploy script that keeps real infra out of a public git repo.
---

# Direct VPS deploy (no Docker, no CI)

Pattern for shipping a `static web build + API` to a shared host you SSH into,
keeping the public repo clean of infra details.

## Topology
- **API**: `uvicorn app.main:app --host 127.0.0.1 --port <PORT>` under a
  **systemd** unit (`/etc/systemd/system/<app>-api.service`). Pick a free port
  (check `ss -ltn`); other apps may use 8000/8787 etc.
- **Web**: static build rsynced to `<DIR>/web`, served by **nginx**; nginx
  proxies `/api/` and `/health` to `127.0.0.1:<PORT>`.
- **TLS**: `certbot --nginx -d <domain>`. Behind Cloudflare (proxied/orange):
  the edge presents Cloudflare's cert; "Full" mode validates your origin's
  Let's Encrypt cert. HTTP-01 works because CF passes port-80 through to origin
  (verify: `curl -H "Host: <domain>" http://127.0.0.1/` returns your app, and
  public `http://<domain>` is NOT force-redirected before reaching origin).
- **Data**: SQLite file at `<DIR>/data/app.db` (ReadWritePaths in the unit).

## Secret / public-repo hygiene (critical)
Real infra values (server IP, SSH user, `/srv/...` paths, ssh key names, phone
ids) **never** go in the repo. Pass them via env at invocation; committed files
use placeholders.

- Deploy scripts read `DEPLOY_HOST=user@ip DEPLOY_SSH_KEY=~/.ssh/key DEPLOY_DIR=... DEPLOY_DOMAIN=...` from the environment.
- Keep the real values in a **gitignored `deploy/deploy.env`** (a few `export`
  lines), loaded right before deploying — don't retype them or paste the IP into
  history each time:
  ```bash
  set -a; . deploy/deploy.env; set +a; ./deploy/deploy.sh
  ```
  Add `deploy/deploy.env` to `.gitignore` and verify with
  `git check-ignore deploy/deploy.env`. Apps sharing one host reuse the same
  `DEPLOY_HOST`/key, differing only in `DEPLOY_DIR` + `DEPLOY_DOMAIN`. The
  canonical real values live in the operator's local/private notes, never the
  public repo.
- Committed systemd unit uses `__USER__` / `__DIR__` placeholders; the bootstrap
  script `sed`-substitutes them from `${DEPLOY_HOST%@*}` and `$DEPLOY_DIR`.
- Grep before committing: `grep -rIE "<IP>|<deploy-user>|/srv/apps" --exclude-dir=.git .` → must be clean.
- The `.env` lives ONLY on the server (`chmod 600`); deploy excludes it from rsync.

## Two scripts

`deploy/bootstrap-remote.sh` (once): create dirs, generate `.env` with a fresh
`JWT_SECRET` (`python3 -c 'import secrets;print(secrets.token_hex(32))'`),
install the systemd unit (sed placeholders) + nginx vhost, reload nginx.

`deploy/deploy.sh` (every deploy):
```bash
set -euo pipefail
HOST=${DEPLOY_HOST:?}; KEY=${DEPLOY_SSH_KEY:?}; DIR=${DEPLOY_DIR:?}; DOMAIN=${DEPLOY_DOMAIN:?}
flutter build web --release --dart-define=API_BASE_URL="https://$DOMAIN"
flutter build apk --release --dart-define=API_BASE_URL="https://$DOMAIN"   # optional
cp build/app/outputs/flutter-apk/app-release.apk build/web/app/app.apk     # ship APK via web
rsync -az --delete -e "ssh -i $KEY" build/web/ "$HOST:$DIR/web/"
rsync -az --delete -e "ssh -i $KEY" --exclude .venv --exclude __pycache__ \
  --exclude '*.db' --exclude .env backend/ "$HOST:$DIR/backend/"
ssh -i "$KEY" "$HOST" 'bash -s' <<EOF
cd $DIR/backend
[ -d .venv ] || python3 -m venv .venv
.venv/bin/pip install -q -e .
sudo systemctl restart <app>-api && sleep 2
curl -fsS http://127.0.0.1:<PORT>/health
EOF
```

## Gotchas that bit, and the fixes
- **`/srv/apps` is root-owned**: first time, `sudo mkdir -p <DIR> && sudo chown <user>:<user> <DIR>` before bootstrap.
- **`python3-venv` missing** on Ubuntu: `sudo apt-get install -y python3.12-venv`, then recreate `.venv`.
- **`.env` with unquoted special chars** (`MAIL_FROM=Time <a@b>`): fine for
  systemd `EnvironmentFile` (no shell parsing) but breaks `. .env` in bash — set
  needed vars explicitly when running CLI tools, don't `source` the prod `.env`.
- **Python version mismatch hides bugs**: local 3.14 evaluates annotations
  lazily (PEP 649), prod 3.12 eagerly. A Pydantic forward-reference
  (`UserOut` using `CategoryDef` defined later) imports fine locally but is a
  `NameError` on the server → service won't start. Define referenced models
  BEFORE their users; don't trust "tests pass locally" for import-order issues.
- **Schema migrations without Alembic**: in `init_db()` after `create_all`, run
  an idempotent `_migrate()` that inspects columns and `ALTER TABLE ... ADD
  COLUMN` if missing. SQLite supports ADD COLUMN.
- **After deploy, ALWAYS check the service came up**: the deploy script's final
  `curl /health` is your canary. If it fails, `ssh ... 'sudo journalctl -u <app>-api -n 30 --no-pager'` shows the import/startup traceback.

## Verify live, end to end
1. `curl https://<domain>/health` and `/api/v1/meta` (through CF).
2. A real auth POST round-trips (even with bad creds → 401 proves the path).
3. For email: trigger it, then `sudo grep <addr> /var/log/mail.log | grep status=sent` (Postfix `250 OK` = delivered).
4. Re-run an interactive emulator test pointed at the LIVE domain as a post-deploy regression.

## Fast iteration
For a backend-only change, skip the web/apk rebuild: `rsync backend/ +
systemctl restart + curl /health`. Full `deploy.sh` only when the web build changed.
