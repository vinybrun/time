import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:time_app/main.dart' as app;

/// Regression guard for the authenticated *empty state*: a freshly-registered
/// user has a stored session but no cached entries. On first load the app mints
/// a new entry id (the day starts asleep at 00:00) and must render the home
/// screen without throwing.
///
/// This is the VM-side companion to `tool/web_smoke.py`. The actual white-screen
/// bug that shipped (`Random.nextInt(1 << 32)`, where `1 << 32 == 0` on the web)
/// only reproduces in a browser, so the web smoke is what truly gates it — but
/// this keeps the empty-state render path covered in the fast `flutter test`
/// suite so any non-numeric regression in it fails locally too.
void main() {
  testWidgets('empty-state authenticated home renders without throwing',
      (tester) async {
    final user = jsonEncode({
      'id': 1,
      'email': 'smoke@test.com',
      'name': 'Smoke',
      'email_verified': true,
      'timezone': 'UTC',
      'language': 'en',
      'categories': null,
    });
    SharedPreferences.setMockInitialValues({
      'flutter.auth_token': 'smoke-token',
      'flutter.auth_user': user,
    });

    app.main();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Where is your focus now?'), findsOneWidget,
        reason: 'home screen did not render for an empty-state user');
  });
}
