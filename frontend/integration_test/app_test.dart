import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:time_app/main.dart' as app;
import 'package:time_app/src/data/api_client.dart';

/// Full-day usability journey: register -> verify -> switch focus through the
/// day -> add & edit history -> change settings. Runs on web (chrome) and on
/// the Android emulator/device. Screenshots are saved by the driver.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  var converted = false;

  Future<void> shot(WidgetTester tester, String name) async {
    await tester.pumpAndSettle(const Duration(milliseconds: 300));
    // On Android the surface must be converted to an image exactly once;
    // subsequent screenshots capture the current frame of that image.
    if (!kIsWeb && !converted) {
      await binding.convertFlutterSurfaceToImage();
      converted = true;
      await tester.pump();
    }
    await binding.takeScreenshot(name);
  }

  testWidgets('full day usability journey', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final email = 'journey${DateTime.now().millisecondsSinceEpoch}@test.com';
    const password = 'password123';

    app.main();
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // tester.enterText does not reach the controller in the Flutter web
    // integration-test harness (the browser owns the text input), so set the
    // field's bound controller directly — the app reads controller.text. Works
    // identically on web and native.
    Future<void> typeInto(Finder field, String text) async {
      tester.widget<TextField>(field).controller!.text = text;
      await tester.pump();
    }

    // --- Register ----------------------------------------------------------
    // Switch to "Create account" mode.
    await tester.tap(find.text('New here? Create an account'));
    await tester.pumpAndSettle();
    await typeInto(find.byType(TextField).at(0), 'Test Journey');
    await typeInto(find.byType(TextField).at(1), email);
    await typeInto(find.byType(TextField).at(2), password);
    await shot(tester, '01_register');
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // --- Verify ------------------------------------------------------------
    final codeResp = await http.get(
        Uri.parse('$kApiBaseUrl/api/v1/auth/dev-code?email=$email'));
    final code = (jsonDecode(codeResp.body) as Map)['code'] as String;
    await typeInto(find.byType(TextField).first, code);
    await shot(tester, '02_verify');
    await tester.tap(find.text('Verify'));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // --- Home: default Sleep focus ----------------------------------------
    expect(find.text('Where is your focus now?'), findsOneWidget);
    await shot(tester, '03_home_default_sleep');

    // --- Switch focus through the day -------------------------------------
    await tester.tap(find.byKey(const ValueKey('focus_work')));
    await tester.pumpAndSettle();
    await shot(tester, '04_focus_work');

    await tester.tap(find.byKey(const ValueKey('focus_leisure')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('focus_growth')));
    await tester.pumpAndSettle();
    await shot(tester, '05_focus_growth');

    // --- Add a manual history entry ---------------------------------------
    await tester.tap(find.byKey(const ValueKey('history_add')));
    await tester.pumpAndSettle();
    await shot(tester, '06_history_added');

    // --- Settings ----------------------------------------------------------
    final settingsBtn = find.widgetWithText(OutlinedButton, 'Settings');
    await tester.ensureVisible(settingsBtn);
    await tester.pumpAndSettle();
    await tester.tap(settingsBtn);
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.text('Account'), findsOneWidget);
    await shot(tester, '07_settings');

    // Back to home.
    final backBtn = find.byTooltip('Back');
    if (backBtn.evaluate().isNotEmpty) {
      await tester.tap(backBtn.first);
      await tester.pumpAndSettle();
    }

    expect(find.text('You can change history'), findsOneWidget);
    await shot(tester, '08_final_home');
  });
}
