import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:time_app/main.dart' as app;
import 'package:time_app/src/data/api_client.dart';
import 'package:time_app/src/widgets/day_scroller.dart';

/// Live production usability run against https://time.sovereinia.org.
/// Logs in as the pre-created test user, seeds a realistic "yesterday" through
/// the live API, then drives the real UI: focus switches, rich donut, settings.
/// Credentials are injected (never hardcoded):
///   --dart-define=TEST_EMAIL=... --dart-define=TEST_PASSWORD=...
const _email = String.fromEnvironment('TEST_EMAIL');
const _password = String.fromEnvironment('TEST_PASSWORD');

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  var converted = false;

  Future<void> shot(WidgetTester tester, String name) async {
    await tester.pumpAndSettle(const Duration(milliseconds: 300));
    if (!kIsWeb && !converted) {
      await binding.convertFlutterSurfaceToImage();
      converted = true;
      await tester.pump();
    }
    await binding.takeScreenshot(name);
  }

  Future<void> waitFor(WidgetTester tester, Finder finder,
      {Duration timeout = const Duration(seconds: 20)}) async {
    final end = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 400));
      if (finder.evaluate().isNotEmpty) return;
    }
    expect(finder, findsWidgets); // fail with a clear message if never shown
  }

  String yesterday() {
    final d = DateTime.now().subtract(const Duration(days: 1));
    return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  Future<void> seedYesterday() async {
    final b = '$kApiBaseUrl/api/v1';
    final login = await http.post(Uri.parse('$b/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': _email, 'password': _password}));
    final token = (jsonDecode(login.body) as Map)['access_token'] as String;
    const schedule = [
      ['sleep', 0, 450], ['self_maintenance', 450, 510], ['work', 510, 720],
      ['leisure', 720, 780], ['work', 780, 1020], ['personal_chores', 1020, 1080],
      ['relationships', 1080, 1170], ['growth', 1170, 1260],
      ['personal_projects', 1260, 1380], ['sleep', 1380, 1440],
    ];
    final day = yesterday();
    final upserts = [
      for (var i = 0; i < schedule.length; i++)
        {'client_id': 'live-$i', 'day': day, 'category': schedule[i][0],
         'start_min': schedule[i][1], 'end_min': schedule[i][2]}
    ];
    await http.post(Uri.parse('$b/entries/sync'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: jsonEncode({'upserts': upserts, 'deletes': []}));
  }

  testWidgets('live production usability', (tester) async {
    expect(_email.isNotEmpty && _password.isNotEmpty, true,
        reason: 'pass TEST_EMAIL / TEST_PASSWORD via --dart-define');
    SharedPreferences.setMockInitialValues({});
    await seedYesterday();

    app.main();
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // Log in (live).
    await tester.enterText(find.byType(TextField).at(0), _email);
    await tester.enterText(find.byType(TextField).at(1), _password);
    await shot(tester, 'live_01_login');
    await tester.tap(find.text('Sign in'));
    await waitFor(tester, find.text('Where is your focus now?'));
    await tester.pumpAndSettle();
    await shot(tester, 'live_02_home');

    // Switch focus on today (creates entries on the prod DB).
    await tester.tap(find.byKey(const ValueKey('focus_work')));
    await tester.pumpAndSettle();
    await shot(tester, 'live_03_focus_work');

    // Show the seeded rich day for yesterday.
    final day = yesterday();
    final chip = find.byKey(ValueKey('day_$day'));
    final dayList = find.descendant(
        of: find.byType(DayScroller), matching: find.byType(Scrollable));
    await tester.scrollUntilVisible(chip, 120, scrollable: dayList, maxScrolls: 200);
    await tester.pumpAndSettle();
    await tester.tap(chip);
    await tester.pumpAndSettle(const Duration(seconds: 1));
    await shot(tester, 'live_04_donut_yesterday');

    // Settings.
    final settingsBtn = find.widgetWithText(OutlinedButton, 'Settings');
    await tester.ensureVisible(settingsBtn);
    await tester.pumpAndSettle();
    await tester.tap(settingsBtn);
    await waitFor(tester, find.text('Account'));
    await tester.pumpAndSettle();
    await shot(tester, 'live_05_settings');
  });
}
