#!/usr/bin/env bash
# Build the Flutter web app and run the web smoke test (tool/web_smoke.py),
# which loads it as a freshly-registered (empty-state) user and fails if the app
# throws an uncaught error — i.e. white-screens. This catches web-only bugs that
# the Dart-VM test suites cannot (see web_smoke.py for the back story).
#
# Self-contained: provisions a matching chromedriver and a throwaway venv with
# selenium if needed. Exit 0 = healthy, non-zero = broken / could not verify.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"           # frontend/
CACHE="${TMPDIR:-/tmp}/time-web-smoke"
mkdir -p "$CACHE"

echo "==> Building Flutter web (debug, for smoke only)"
( cd "$ROOT" && flutter build web --dart-define=API_BASE_URL="${API_BASE_URL:-http://localhost:8799}" >/dev/null )

# --- chromedriver matching the installed Chrome -----------------------------
CHROME_BIN="$(command -v google-chrome || command -v chromium || command -v chromium-browser || true)"
if [ -z "$CHROME_BIN" ]; then
  echo "FAIL: no Chrome/Chromium found — cannot run the web smoke test." >&2
  exit 2
fi
DRIVER="${CHROMEDRIVER:-}"
if [ -z "$DRIVER" ]; then
  VER="$("$CHROME_BIN" --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | head -1)"
  DRIVER="$CACHE/chromedriver-$VER"
  if [ ! -x "$DRIVER" ]; then
    echo "==> Fetching chromedriver $VER"
    URL="https://storage.googleapis.com/chrome-for-testing-public/$VER/linux64/chromedriver-linux64.zip"
    curl -fsSL -o "$CACHE/cd.zip" "$URL"
    ( cd "$CACHE" && unzip -oq cd.zip )
    cp "$CACHE/chromedriver-linux64/chromedriver" "$DRIVER"
    chmod +x "$DRIVER"
  fi
fi

# --- selenium (throwaway venv if not importable) ----------------------------
PY="python3"
if ! $PY -c "import selenium" 2>/dev/null; then
  echo "==> Creating venv with selenium"
  $PY -m venv "$CACHE/venv"
  "$CACHE/venv/bin/pip" install -q --upgrade pip selenium
  PY="$CACHE/venv/bin/python"
fi

echo "==> Running web smoke"
exec "$PY" "$ROOT/tool/web_smoke.py" \
  --build-dir "$ROOT/build/web" --chromedriver "$DRIVER"
