---
name: android-on-device-testing
description: Run and test a Flutter app on a physical Android phone (especially MIUI/HyperOS/Xiaomi) and on a headless emulator without triggering permission/uninstall prompts that get the test stuck. Use when asked to install/test an app on a real phone over adb, when "INSTALL_FAILED_USER_RESTRICTED" appears, when emulator booting/segfaulting, or when adb shell input is blocked. Codifies the never-uninstall / install-r-release / .debug-suffix rules.
---

# Android on-device + emulator testing

## Emulator that actually boots (headless host)
- Software GPU (`-gpu swiftshader_indirect`) often **segfaults** (exit 139) and
  `-no-window` can crash. If there's a real display (`echo $DISPLAY` → `:0`),
  launch **with a window and host GPU**: `emulator -avd <AVD> -no-snapshot -no-audio -gpu host`.
- Launch it with the harness's persistent background mechanism
  (`run_in_background: true`), NOT a bare `&`/`nohup` inside a one-shot Bash
  call — those children get reaped when the call returns (cold boot never
  finishes, adb never sees the device).
- Wait for boot with a bounded loop: `until [ "$(adb shell getprop sys.boot_completed)" = 1 ]; do sleep 6; done`.
  Host loopback from inside the emulator is **`10.0.2.2`** (use it as API_BASE_URL).

## Physical phone (MIUI / HyperOS / Xiaomi) — the rules
Connected via wireless debugging; the flutter/adb device id is the long
`adb-<SERIAL>-...._adb-tls-connect._tcp` mDNS name. `adb shell input` is blocked
(SecurityException) — drive UI via `flutter drive`/`integration_test`, not input
injection.

**Never violate these or a human gets stuck approving prompts on the phone:**
- **NEVER `adb uninstall`** the app (clears data + permissions → full
  re-authorization on next install).
- **Update only with `adb -s <id> install -r <release-apk>`** (reinstall, no
  uninstall prompt). Release APK: `build/app/outputs/flutter-apk/app-release.apk`.
- **`flutter test integration_test` builds a DEBUG apk** with a different
  signing cert → MIUI revokes runtime permissions / shows "install canceled".
  Avoid polluting the real app: give debug its own package id so the two live
  side-by-side and tests never touch the release app:
  ```kotlin
  // android/app/build.gradle.kts -> android { buildTypes {
  debug { applicationIdSuffix = ".debug"; versionNameSuffix = "-debug" }
  ```
  Then the test build installs as `<pkg>.debug`; the release `<pkg>` stays clean.
- `INSTALL_FAILED_USER_RESTRICTED` = phone's **"Install via USB" got
  re-disabled** (MIUI does this). No adb flag bypasses it — the human must
  re-enable it in Developer options. Note this to the user; don't loop.
- Apps with **no runtime permissions** (no location/camera) are low-risk for the
  permission-reset loop; still keep the `.debug` separation.

## Driving + observing without input injection
- Launch like a user tap: `adb shell monkey -p <pkg> -c android.intent.category.LAUNCHER 1`
- Screenshot after each step: `adb exec-out screencap -p > step.png`
- "What's on screen" (text): `adb shell uiautomator dump /sdcard/ui.xml; adb pull /sdcard/ui.xml; grep -oP '(?<=text=")[^"]+' ui.xml`
- Deep link: `adb shell am start -n <pkg>/.MainActivity -a android.intent.action.VIEW -d "<url>"`
- Real taps for a usability run: `flutter drive ... -d "<mDNS-id>" --dart-define=API_BASE_URL=https://<prod-domain>` (debug variant; release app untouched).

## After any debug-install test
Immediately re-`install -r` the release APK if you didn't use the `.debug`
suffix, so the "real" app the user taps is the clean release build.
