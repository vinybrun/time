import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:time_app/main.dart' as app;
import 'package:time_app/src/data/api_client.dart';

/// Proves the "forgot password" flow end-to-end against the local backend
/// (EXPOSE_CODES=true): forgot -> emailed code -> reset -> logged in.
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

  Future<String> post(String path, Map body) async {
    final r = await http.post(Uri.parse('$kApiBaseUrl/api/v1$path'),
        headers: {'Content-Type': 'application/json'}, body: jsonEncode(body));
    return r.body;
  }

  testWidgets('forgot password flow', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final email = 'forgot${DateTime.now().millisecondsSinceEpoch}@test.com';

    // Create a verified user via the backend.
    final reg = await post('/auth/register',
        {'email': email, 'password': 'oldpassword1', 'name': 'Forgot'});
    final code = (jsonDecode(reg) as Map)['dev_code'] as String;
    await post('/auth/verify', {'email': email, 'code': code});

    app.main();
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // Tap "Forgot password?".
    await tester.tap(find.text('Forgot password?'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, email);
    await shot(tester, 'forgot_01_email');
    await tester.tap(find.text('Send reset code'));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // Fetch the reset code from the backend (re-issues a known code).
    final fp = await post('/auth/forgot-password', {'email': email});
    final resetCode = (jsonDecode(fp) as Map)['dev_code'] as String;
    await tester.enterText(find.byType(TextField).at(0), resetCode);
    await tester.enterText(find.byType(TextField).at(1), 'brandnew123');
    await shot(tester, 'forgot_02_reset');
    await tester.tap(find.text('Reset password'));
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // Reset logs the user straight in.
    expect(find.text('Where is your focus now?'), findsOneWidget);
    await shot(tester, 'forgot_03_home');
  });
}
