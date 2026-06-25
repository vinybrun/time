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

/// Seeds a balanced full 24h for *yesterday* through the real backend, logs in
/// through the UI, selects yesterday, and screenshots the rich donut — every
/// category, ordered by first entry of the day. Also covers the login flow.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  String yesterday() {
    final d = DateTime.now().subtract(const Duration(days: 1));
    return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  Future<void> seed(String email, String password, String day) async {
    final b = '$kApiBaseUrl/api/v1';
    Future<http.Response> post(String p, Map body, [String? tok]) => http.post(
          Uri.parse('$b$p'),
          headers: {
            'Content-Type': 'application/json',
            if (tok != null) 'Authorization': 'Bearer $tok',
          },
          body: jsonEncode(body),
        );
    await post('/auth/register', {'email': email, 'password': password, 'name': 'Demo'});
    final codeResp =
        await http.get(Uri.parse('$b/auth/dev-code?email=$email'));
    final code = (jsonDecode(codeResp.body) as Map)['code'] as String;
    final verify = await post('/auth/verify', {'email': email, 'code': code});
    final token = (jsonDecode(verify.body) as Map)['access_token'] as String;

    const schedule = [
      ['sleep', 0, 450],
      ['self_maintenance', 450, 510],
      ['work', 510, 720],
      ['leisure', 720, 780],
      ['work', 780, 1020],
      ['personal_chores', 1020, 1080],
      ['relationships', 1080, 1170],
      ['growth', 1170, 1260],
      ['personal_projects', 1260, 1380],
      ['sleep', 1380, 1440],
    ];
    final upserts = [
      for (var i = 0; i < schedule.length; i++)
        {
          'client_id': 'demo-$i',
          'day': day,
          'category': schedule[i][0],
          'start_min': schedule[i][1],
          'end_min': schedule[i][2],
        }
    ];
    await post('/entries/sync', {'upserts': upserts, 'deletes': []}, token);
  }

  testWidgets('rich full-day donut for yesterday', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final email = 'demo${DateTime.now().millisecondsSinceEpoch}@test.com';
    const password = 'password123';
    final day = yesterday();
    await seed(email, password, day);

    app.main();
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // Log in (default screen is Sign in).
    await tester.enterText(find.byType(TextField).at(0), email);
    await tester.enterText(find.byType(TextField).at(1), password);
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle(const Duration(seconds: 3));
    expect(find.text('Where is your focus now?'), findsOneWidget);

    // Select yesterday in the (lazy, horizontal) day scroller -> its full donut.
    final chip = find.byKey(ValueKey('day_$day'));
    final dayList = find.descendant(
        of: find.byType(DayScroller), matching: find.byType(Scrollable));
    await tester.scrollUntilVisible(chip, 120, scrollable: dayList, maxScrolls: 200);
    await tester.pumpAndSettle();
    await tester.tap(chip);
    await tester.pumpAndSettle(const Duration(seconds: 1));

    if (!kIsWeb) {
      await binding.convertFlutterSurfaceToImage();
      await tester.pump();
    }
    await binding.takeScreenshot('09_donut_full_day');
  });
}
