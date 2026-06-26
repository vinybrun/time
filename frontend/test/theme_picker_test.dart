import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:time_app/l10n/app_localizations.dart';
import 'package:time_app/src/models/category.dart';
import 'package:time_app/src/theme.dart';
import 'package:time_app/src/widgets/pickers.dart';

void main() {
  testWidgets('pickCategory opens a centered Dialog (not a bottom sheet)',
      (tester) async {
    final cats = defaultCategories();
    await tester.pumpWidget(MaterialApp(
      theme: buildTheme(kOffWhitePalette),
      localizationsDelegates: AppL10n.localizationsDelegates,
      supportedLocales: AppL10n.supportedLocales,
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () => pickCategory(context, cats, 'work'),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // It's a Dialog, and the selected category shows a check.
    expect(find.byType(Dialog), findsOneWidget);
    expect(find.byType(BottomSheet), findsNothing);
    expect(find.byIcon(Icons.check), findsOneWidget);
  });
}
