---
name: flutter-fastapi-localfirst
description: Architecture pattern for a calm, local-first Flutter app (web + Android) backed by a small FastAPI + SQLite service with email-verified auth, offline-first sync, i18n, and user-customizable categories. Use when building a single-purpose Flutter app with accounts that should feel instant (no spinners), sync across devices, support multiple languages, and ship as both web and APK.
---

# Flutter + FastAPI local-first app

Blueprint for a small accountability/tracker-style app (e.g. a time tracker).
Layout: `backend/` (FastAPI+SQLite), `frontend/` (Flutter), `deploy/` (see the
`direct-vps-deploy` skill).

## Backend (FastAPI + SQLite + SQLAlchemy)
- **Auth**: email+password, **email verification by 6-digit code**. Store the
  code **hashed** (sha256) with an expiry; `bcrypt` for passwords; JWT
  (PyJWT) for sessions (long TTL for a personal app). Endpoints under
  `/api/v1`: `auth/{register,verify,login,resend,forgot-password,reset-password}`,
  `me` (+ `me/password`, `me/export`, DELETE `me`), `entries` (+ `entries/sync`).
- **No account enumeration**: `forgot-password`/`resend` return the same
  response whether or not the email exists. Share one `_issue_code(db,user,purpose)`
  + `_consume_code(...)` helper across verify/reset.
- **Email** via the host's local Postfix: `smtplib` to `localhost:25`, From a
  real mailbox on the box. Wrap sends in try/except so email failure never 500s
  registration. **HTML email gotcha**: a code styled with big `letter-spacing`
  wraps on narrow clients — add `white-space:nowrap` (and test the rendered
  mail, not just that it "sent").
- **Local-dev shortcut**: an `EXPOSE_CODES=true` flag returns `dev_code` in the
  response / a `GET /auth/dev-code` endpoint, so automated E2E can verify
  without reading a mailbox. MUST default false in prod.
- **Offline-first sync**: entries carry a client-generated stable `client_id`;
  `POST /entries/sync {upserts, deletes}` is an idempotent bulk upsert that
  returns the authoritative set. Validate per-user isolation (always filter by
  `user_id`).
- **User-owned config (categories)**: store as a JSON column on the user; the
  server validates only a safe key shape (`^[a-z0-9_]{1,32}$`), the client owns
  labels/colors/order. Add the column via an idempotent `_migrate()` (ALTER
  TABLE ADD COLUMN) so existing prod DBs upgrade on startup.
- **Tests**: FastAPI `TestClient` with an in-memory SQLite + a fixture that
  monkeypatches the email senders to capture codes. Cover: verify gates login,
  reset flow, custom/invalid category keys, export shape, delete cascades.

## Frontend (Flutter, Riverpod, local-first)
- **No loading spinners in normal use**: render from a `shared_preferences`
  cache instantly, sync in the background. `EntriesNotifier` writes the cache on
  every mutation and schedules `pushSync()`; the home screen pulls on init/resume.
- **State**: Riverpod `ChangeNotifierProvider`s for auth, entries, categories;
  a `StreamProvider` ticking every ~20s for live "running" durations + day
  rollover. Decouple providers from each other's rebuilds with `ref.read` inside
  callbacks (don't `ref.watch(auth)` in a provider you don't want recreated).
- **Dynamic categories**: entry.category is a **string key**; a `CategoriesNotifier`
  resolves key → `CategoryDef{label,color,native,enabled,order}`. Native labels
  fall back to localized strings unless renamed; unknown/deleted keys resolve to
  a gray fallback so old entries still render. Settings can disable native,
  add/remove custom, recolor, rename — synced via the user's JSON config.
- **i18n**: ARB files via `gen_l10n` for all supported languages. Include the
  `GlobalMaterialLocalizations`/`Cupertino`/`Widgets` delegates in
  `localizationsDelegates` — they initialize `intl` date symbols for the active
  locale, so `DateFormat(locale)` won't throw for non-`en` users. (Only if you
  format dates *without* those delegates do you need `initializeDateFormatting()`
  in `main()`; see `flutter-web-e2e-testing`.)
- **Theme**: a calm off-white "paper" palette by default. For runtime theming
  (a dark mode, or a time-of-day "circadian" theme) make the palette an
  `AppPalette extends ThemeExtension<AppPalette>` registered in `ThemeData` and
  read via a `context.c` getter — NOT static `Color` consts. Static colours
  can't change at runtime, and turning them dynamic breaks every `const` widget
  that used them (you'd have to un-`const` those anyway). A `CustomPainter`
  (donut/ring) can't read context, so pass the palette into it and add it to
  `shouldRepaint`. Circadian = a few keyframe palettes (night/sunrise/day/sunset)
  lerped by the local hour, driven by a 1-minute clock provider that's only
  watched while that theme is active; cross-fade swaps with MaterialApp's
  `themeAnimationDuration`. Clamp painter label positions inside the canvas so
  they never clip on phones.
- **Centred day / horizontal picker**: to keep "today" (or the selected item) in
  the middle, pad the list by half the viewport on each side — then the centre
  offset of item i is simply its content-space centre, independent of viewport
  width, so you can set `initialScrollOffset` without waiting for layout
  (`ListView.builder`'s maxScrollExtent is wrong on the first frame). Include
  each slot's **margins** in that width, or centring drifts by margin×index.
  Enable mouse/trackpad dragging with `ScrollConfiguration(dragDevices: {touch,
  mouse, trackpad, stylus})` — Flutter web won't drag-scroll with a mouse else.
- **Cross-platform export**: conditional import
  `export 'exporter_io.dart' if (dart.library.js_interop) 'exporter_web.dart';`
  — web does a Blob+anchor download via `package:web`, mobile copies to clipboard.
- **Web password managers**: give email/password/name fields `autofillHints` and
  wrap them in an `AutofillGroup`, or managers can't fill them.
- **Keys for testability**: stable `ValueKey`s on focus buttons, add-entry
  button, day chips (see `flutter-web-e2e-testing`).

## Build + ship
`flutter build web --release --dart-define=API_BASE_URL=https://<domain>` and
`flutter build apk --release ...`; host the APK at `/app/<app>.apk` and offer a
web-footer download link (gate it with `kIsWeb`). App icon: generate from one
source with `flutter_launcher_icons` (Android adaptive + web favicon/manifest);
fix the default `time_app` web title/manifest name to the real app name.
