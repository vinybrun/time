import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:time_app/main.dart' as app;
import 'package:time_app/src/data/api_client.dart';

/// Exercises iteration-2 features against the local backend: custom categories
/// (add + disable native), reflected in the focus buttons, plus data export.
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

  testWidgets('custom categories + export', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final email = 'feat${DateTime.now().millisecondsSinceEpoch}@test.com';
    final reg = await http.post(Uri.parse('$kApiBaseUrl/api/v1/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': 'password123', 'name': 'Feat'}));
    final code = (jsonDecode(reg.body) as Map)['dev_code'] as String;
    await http.post(Uri.parse('$kApiBaseUrl/api/v1/auth/verify'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'code': code}));

    app.main();
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // Log in through the UI.
    await tester.enterText(find.byType(TextField).at(0), email);
    await tester.enterText(find.byType(TextField).at(1), 'password123');
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle(const Duration(seconds: 3));
    expect(find.text('Where is your focus now?'), findsOneWidget);

    // Open Settings -> Categories.
    final settingsBtn = find.widgetWithText(OutlinedButton, 'Settings');
    await tester.ensureVisible(settingsBtn);
    await tester.pumpAndSettle();
    await tester.tap(settingsBtn);
    await tester.pumpAndSettle(const Duration(seconds: 1));
    final catBtn = find.byIcon(Icons.palette_outlined);
    await tester.ensureVisible(catBtn);
    await tester.pumpAndSettle();
    await tester.tap(catBtn);
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.text('Add category'), findsOneWidget);

    // Disable the first native category (Work).
    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();

    // Add a custom category "Yoga".
    await tester.tap(find.text('Add category'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Yoga');
    await tester.tap(find.widgetWithText(FilledButton, 'Add'));
    await tester.pumpAndSettle();
    expect(find.text('Yoga'), findsWidgets);
    await shot(tester, 'feat_01_categories');

    // Back to settings, export (clipboard on Android), then back home.
    await tester.pageBack();
    await tester.pumpAndSettle();
    final exportBtn = find.text('Export my data');
    await tester.ensureVisible(exportBtn);
    await tester.pumpAndSettle();
    await tester.tap(exportBtn);
    await tester.pumpAndSettle(const Duration(seconds: 1));
    await shot(tester, 'feat_02_export');

    await tester.pageBack();
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // Focus buttons now show Yoga and no longer show Work.
    expect(find.text('Yoga'), findsWidgets);
    expect(find.text('Work'), findsNothing);
    await shot(tester, 'feat_03_home_custom');
  });
}
