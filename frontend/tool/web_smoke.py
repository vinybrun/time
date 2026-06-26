#!/usr/bin/env python3
"""Web smoke test: load the built web app as a freshly-registered (empty-state)
user and assert it boots with zero uncaught errors.

This exists because the test suites run on the Dart VM, where web-only numeric
semantics don't apply. A real bug shipped this way: the entry-id generator used
`Random.nextInt(1 << 32)`, and on the web `1 << 32 == 0` (JS 32-bit shifts), so
`nextInt(0)` threw and white-screened the app for every new user. The VM tests
were green; nobody knew production was broken.

What it does:
  1. Serves `build/web` (you must `flutter build web` first).
  2. Injects a fabricated authenticated session with NO cached entries into
     localStorage (exactly a just-verified user). No backend required — the home
     renders from cache and background sync fails silently.
  3. Loads the app in headless Chrome and fails if any uncaught error reaches the
     browser console (Dart exceptions surface there as SEVERE), which is what a
     white screen looks like from the outside.

Usage:
  python3 tool/web_smoke.py [--build-dir build/web] [--chromedriver PATH]
Exit code 0 = healthy, 1 = white screen / console error, 2 = setup problem.
"""
import argparse
import contextlib
import functools
import http.server
import json
import os
import socketserver
import sys
import threading
import time

try:
    from selenium import webdriver
    from selenium.webdriver.chrome.options import Options
    from selenium.webdriver.chrome.service import Service
except ImportError:
    print("SETUP: selenium not installed (pip install selenium)", file=sys.stderr)
    sys.exit(2)


def serve(directory, port):
    handler = functools.partial(
        http.server.SimpleHTTPRequestHandler, directory=directory)
    socketserver.TCPServer.allow_reuse_address = True
    httpd = socketserver.TCPServer(("127.0.0.1", port), handler)
    threading.Thread(target=httpd.serve_forever, daemon=True).start()
    return httpd


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--build-dir", default="build/web")
    ap.add_argument("--chromedriver", default=os.environ.get("CHROMEDRIVER"))
    ap.add_argument("--port", type=int, default=8771)
    args = ap.parse_args()

    if not os.path.isfile(os.path.join(args.build_dir, "index.html")):
        print(f"SETUP: {args.build_dir}/index.html missing — run "
              "`flutter build web` first", file=sys.stderr)
        return 2

    # A just-verified user: a valid session but no cached entries. The 'flutter.'
    # prefix and the double JSON encoding match how shared_preferences_web stores
    # a String (the user map is already a JSON string, then the web layer
    # json-encodes that string again).
    user = json.dumps({
        "id": 1, "email": "smoke@test.com", "name": "Smoke",
        "email_verified": True, "timezone": "UTC", "language": "en",
        "categories": None,
    })

    httpd = serve(args.build_dir, args.port)
    opts = Options()
    opts.add_argument("--headless=new")
    opts.add_argument("--no-sandbox")
    opts.add_argument("--window-size=390,844")
    opts.set_capability("goog:loggingPrefs", {"browser": "ALL"})
    service = Service(args.chromedriver) if args.chromedriver else Service()
    try:
        driver = webdriver.Chrome(service=service, options=opts)
    except Exception as e:  # noqa: BLE001
        print(f"SETUP: could not start Chrome/chromedriver: {e}", file=sys.stderr)
        httpd.shutdown()
        return 2

    url = f"http://127.0.0.1:{args.port}/"
    try:
        driver.get(url)
        time.sleep(3)
        driver.execute_script(
            "window.localStorage.setItem('flutter.auth_token', arguments[0]);"
            "window.localStorage.setItem('flutter.auth_user', arguments[1]);",
            json.dumps("smoke-token"), json.dumps(user))
        driver.get(url)
        time.sleep(8)

        # Chrome logs failed network requests as SEVERE too. Those are expected
        # here (the fabricated token => 401 on best-effort sync/refresh, which
        # the app swallows). We only care about *uncaught code errors* — a Dart
        # exception that crashes the build to a white screen surfaces in the
        # console from main.dart.js with an error signature, never as a "Failed
        # to load resource" line.
        def is_code_error(msg):
            if "Failed to load resource" in msg:
                return False
            return ("main.dart.js" in msg
                    or any(sig in msg for sig in (
                        "Error:", "Exception", "RangeError", "TypeError",
                        "Uncaught", "Assertion")))

        crashes = [e for e in driver.get_log("browser")
                   if e["level"] == "SEVERE" and is_code_error(e["message"])]
        if crashes:
            print("FAIL: app threw an uncaught error on empty-state load "
                  "(white screen):", file=sys.stderr)
            for e in crashes:
                print("  " + e["message"][:600], file=sys.stderr)
            return 1
        print("OK: empty-state authenticated home loaded with no code errors")
        return 0
    finally:
        with contextlib.suppress(Exception):
            driver.quit()
        httpd.shutdown()


if __name__ == "__main__":
    sys.exit(main())
