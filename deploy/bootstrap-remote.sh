#!/usr/bin/env bash
# One-time server bootstrap for the Time app (run ONCE on first deploy).
# Idempotent where practical. Real values passed via env at invocation.
#
#   DEPLOY_HOST=user@host DEPLOY_SSH_KEY=~/.ssh/your-key \
#   DEPLOY_DIR=/srv/apps/time DEPLOY_DOMAIN=time.sovereinia.org \
#   ./deploy/bootstrap-remote.sh
#
# Creates dirs + .env (with a fresh JWT secret), installs the systemd unit and
# nginx vhost, and requests a TLS cert. Run deploy.sh first to populate files,
# or run this then deploy.sh.
set -euo pipefail
HOST="${DEPLOY_HOST:?}"; KEY="${DEPLOY_SSH_KEY:?}"; DIR="${DEPLOY_DIR:?}"; DOMAIN="${DEPLOY_DOMAIN:?}"
USER_NAME="${HOST%@*}"   # the login user, derived from user@host
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SSH="ssh -i $KEY -o StrictHostKeyChecking=accept-new"

echo "==> Creating dirs + .env (if missing)"
$SSH "$HOST" "bash -s" <<EOF
set -euo pipefail
mkdir -p $DIR/web $DIR/backend $DIR/data
if [ ! -f $DIR/.env ]; then
  SECRET=\$(python3 -c 'import secrets;print(secrets.token_hex(32))')
  cat > $DIR/.env <<ENV
DATABASE_URL=sqlite:///$DIR/data/time.db
JWT_SECRET=\$SECRET
ACCESS_TOKEN_TTL_HOURS=720
SMTP_HOST=localhost
SMTP_PORT=25
SMTP_USE_TLS=false
MAIL_FROM=Time <time@alterspring.org>
CODE_TTL_MINUTES=30
EXPOSE_CODES=false
CORS_ORIGINS=https://$DOMAIN
APP_BASE_URL=https://$DOMAIN
ENV
  chmod 600 $DIR/.env
  echo ".env created"
else
  echo ".env already exists, leaving it"
fi
EOF

echo "==> Installing systemd unit (substituting user=$USER_NAME dir=$DIR)"
sed -e "s|__USER__|$USER_NAME|g" -e "s|__DIR__|$DIR|g" "$ROOT/deploy/time-api.service" \
  | $SSH "$HOST" "sudo tee /etc/systemd/system/time-api.service >/dev/null"
$SSH "$HOST" "sudo systemctl daemon-reload"

echo "==> Installing nginx vhost (port 80)"
$SSH "$HOST" "sudo tee /etc/nginx/sites-available/time.sovereinia.org.conf >/dev/null" < "$ROOT/deploy/nginx/time.sovereinia.org.conf"
$SSH "$HOST" "sudo ln -sf /etc/nginx/sites-available/time.sovereinia.org.conf /etc/nginx/sites-enabled/ && sudo nginx -t && sudo systemctl reload nginx"

echo "==> Done. Now run deploy.sh, then:"
echo "    sudo systemctl enable --now time-api"
echo "    sudo certbot --nginx -d $DOMAIN"
