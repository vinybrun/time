#!/usr/bin/env bash
# Direct deploy (no Docker, no CI) for the Time app.
#
# Real infra values are passed via env at invocation — never committed:
#   DEPLOY_HOST=user@host \
#   DEPLOY_SSH_KEY=~/.ssh/your-key \
#   DEPLOY_DIR=/srv/apps/time \
#   DEPLOY_DOMAIN=time.sovereinia.org \
#   ./deploy/deploy.sh
#
# Builds the Flutter web app, rsyncs web + backend to the server, installs/updates
# the Python venv, and restarts the systemd service.
set -euo pipefail

HOST="${DEPLOY_HOST:?set DEPLOY_HOST=user@ip}"
KEY="${DEPLOY_SSH_KEY:?set DEPLOY_SSH_KEY=~/.ssh/key}"
DIR="${DEPLOY_DIR:?set DEPLOY_DIR=/srv/apps/time}"
DOMAIN="${DEPLOY_DOMAIN:?set DEPLOY_DOMAIN=time.sovereinia.org}"

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SSH="ssh -i $KEY -o StrictHostKeyChecking=accept-new"
RSYNC_E="ssh -i $KEY -o StrictHostKeyChecking=accept-new"

echo "==> Building Flutter web (API → https://$DOMAIN)"
cd "$ROOT/frontend"
flutter build web --release --dart-define=API_BASE_URL="https://$DOMAIN"

echo "==> Building release APK"
flutter build apk --release --dart-define=API_BASE_URL="https://$DOMAIN"
mkdir -p "$ROOT/frontend/build/web/app"
cp "$ROOT/frontend/build/app/outputs/flutter-apk/app-release.apk" \
   "$ROOT/frontend/build/web/app/time.apk"

echo "==> Syncing web build (incl. /app/time.apk) → $HOST:$DIR/web"
$SSH "$HOST" "mkdir -p $DIR/web $DIR/backend $DIR/data"
rsync -az --delete -e "$RSYNC_E" "$ROOT/frontend/build/web/" "$HOST:$DIR/web/"

echo "==> Syncing backend → $HOST:$DIR/backend"
rsync -az --delete -e "$RSYNC_E" \
  --exclude '.venv' --exclude '__pycache__' --exclude '*.db' \
  --exclude '.env' --exclude '*.pyc' \
  "$ROOT/backend/" "$HOST:$DIR/backend/"

echo "==> Installing deps + restarting service"
$SSH "$HOST" "bash -s" <<EOF
set -euo pipefail
cd $DIR/backend
if [ ! -d .venv ]; then python3 -m venv .venv; fi
.venv/bin/pip install -q --upgrade pip
.venv/bin/pip install -q -e .
sudo systemctl restart time-api
sleep 2
curl -fsS http://127.0.0.1:8810/health && echo " <- backend healthy"
EOF

echo "==> Done. Live at https://$DOMAIN"
