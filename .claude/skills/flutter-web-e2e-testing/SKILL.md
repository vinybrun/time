---
name: flutter-web-e2e-testing
description: Catch Flutter web-only crashes (blank/white screen) that VM tests miss, and drive real input + screenshots on web and Android. Use when a deployed Flutter web app shows a blank screen, when "it passes tests but breaks in the browser", or when you need a browser smoke test that fails on console/JS errors.
---

# Flutter web + Android E2E testing

## #1 lesson: VM tests can't see web-only runtime bugs

`flutter test` runs on the Dart VM. Dart-on-web (dart2js) compiles ints to JS
numbers, so numeric/bit semantics differ and code that's correct on the VM can
throw only in a browser — crashing the whole app to a blank page. Real example
from this project: `Random().nextInt(1 << 32)` — on the web `1 << 32 == 0`
(JS shifts are 32-bit), so `nextInt(0)` threw a `RangeError` and white-screened
every freshly-registered user. All VM tests stayed green.

Rules:
- Use plain literal bounds (`0xFFFFFFFF`), never `1 << 32`, for web-bound ints.
- A blank screen that **persists after refresh** but where the login screen
  renders fine = a deterministic throw on the authenticated/home render path
  (something in stored state crashes the build every load).
- **Add a browser smoke gate** (below). The VM suite is necessary but not
  sufficient; only a browser run catches this class.

(Not a bug here, but a common cousin: `DateFormat(locale)` throws
`LocaleDataException` for non-`en` locales *unless* date symbols are initialized.
`flutter_localizations`' `GlobalMaterialLocalizations.delegate` does that for the
active locale, so apps using it are fine. Only call `initializeDateFormatting()`
yourself if you format dates without those delegates.)

## Browser smoke gate (the cheap thing that catches blank screens)

Load the built app as the worst-case user and fail on any uncaught error — no
UI driving needed. The empty-state authenticated user (a brand-new account with
no cached data) is the easily-missed case.

1. `flutter build web` and serve `build/web` with a plain static server.
2. Inject a session into `localStorage` so the app boots straight to the home
   screen — no backend needed (background sync fails silently):
   - keys are prefixed `flutter.` (e.g. `flutter.auth_token`).
   - `shared_preferences` web stores a String as `json.encode(value)`. A value
     your code already JSON-encoded before `setString` (e.g. the user object)
     is therefore **double-encoded**: `JSON.stringify(JSON.stringify(user))`.
3. Read the browser console; **fail on any uncaught error**. Chrome also logs
   failed network requests as SEVERE — ignore lines containing
   `Failed to load resource` (expected with a fabricated token); a render crash
   shows up from `main.dart.js` with an error signature (`RangeError`,
   `TypeError`, `Error:`…).

Selenium + a **version-matched** chromedriver works well (download the driver
for your exact `google-chrome --version` from chrome-for-testing). See
`frontend/tool/web_smoke.py` for a working implementation; wire it into the
deploy script as a pre-ship gate.

CanvasKit release builds render to `<canvas>` — `document.body.innerText` is
empty, so assert via the console (above) or by inspecting a screenshot, not DOM
text.

## Driving real input: flutter_drive + integration_test

`flutter test integration_test/foo.dart` does NOT save screenshots (no driver)
and web devices aren't supported there. Use `flutter drive` with a screenshot
driver. Web needs a `chromedriver` on :4444 (`-d web-server`).

- **`tester.enterText` does NOT reach the controller in the web harness** (the
  browser owns text input) — every field stays empty and form POSTs go out
  blank (→ 422). Set the field's bound controller directly instead; works on web
  and native:
  ```dart
  tester.widget<TextField>(field).controller!.text = value;
  await tester.pump();
  ```
- Android screenshots need the surface converted to an image **exactly once**
  per process, then reused (a second call throws `'!_isSurfaceRendered'`):
  ```dart
  if (!kIsWeb && !converted) { await binding.convertFlutterSurfaceToImage(); converted = true; await tester.pump(); }
  await binding.takeScreenshot(name);
  ```
- Don't trust `pumpAndSettle(Duration)` after navigation — the Duration is the
  pump interval, not a timeout, and a `Timer.periodic` can let it return before
  a network call lands. Poll instead:
  ```dart
  Future<void> waitFor(t, finder, {timeout = const Duration(seconds: 20)}) async {
    final end = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(end)) { await t.pump(const Duration(milliseconds: 400)); if (finder.evaluate().isNotEmpty) return; }
    expect(finder, findsWidgets);
  }
  ```
- Off-screen widgets aren't hittable: `tester.ensureVisible(f)` then tap. Lazy
  lists: `scrollUntilVisible(chip, 120, scrollable: ...)`.
- Add stable `ValueKey`s to interactive widgets so finders don't depend on text.

Screenshot driver (`test_driver/integration_test.dart`):
```dart
import 'package:integration_test/integration_test_driver_extended.dart';
Future<void> main() => integrationDriver(onScreenshot: (name, bytes, [_]) async {
  File('proofs_shots/$name.png').writeAsBytesSync(bytes); return true; });
```

To verify against a real backend, expose verification codes in dev only
(`EXPOSE_CODES=true` / a `GET /auth/dev-code` endpoint) so register→verify can
run unattended; default it off in prod.

## Debug a stuck real phone (adb + Chrome DevTools Protocol)

When the app is blank on a physical phone but fine on your machine, read the real
error straight from the phone's browser:
- `adb -t <id> forward tcp:9222 localabstract:chrome_devtools_remote`, then
  `curl localhost:9222/json/list` to find the time tab's `webSocketDebuggerUrl`.
- Open the CDP websocket with **`suppress_origin=True`** — recent Chrome rejects
  the handshake with `403 Forbidden` if any `Origin` header is sent.
- Enable `Runtime`/`Log`, `Page.reload`, collect `Runtime.exceptionThrown` for the
  actual uncaught error. `performance.getEntriesByType('resource')` with
  `transferSize:0` for `main.dart.js` means it was served from the browser's HTTP
  cache (stale build); `fetch(url+'?cb='+Date.now(),{cache:'no-store'})` reveals
  the network's real size.
- Un-stick it without clearing site data: `Page.reload {ignoreCache:true}`. The
  permanent fix is `Cache-Control: no-cache` on the unhashed Flutter entrypoints
  (`main.dart.js`, `flutter_bootstrap.js`, the service worker, `index.html`,
  `version.json`) — see `direct-vps-deploy`. A stale CDN/browser cache is the
  usual reason "PC works, phone is blank" after a deploy.

## Practical notes
- Builds take minutes — run `flutter drive` with `run_in_background: true` and
  poll the log for a sentinel line; don't chain `sleep`s.
- `google-chrome --headless --screenshot URL --window-size=...` (chrome itself,
  no chromedriver) is a reliable fallback for render/responsive proofs.
- Headless Chrome enforces a **minimum window width (~500px)** — `--window-size=
  390,...` still reports `innerWidth: 500`. For a true phone width use Selenium
  `mobileEmulation` deviceMetrics (sets width, devicePixelRatio, touch, UA).
- Look at the screenshots — a green test with a blank screenshot is a red app.
