import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../models/category.dart';
import '../theme.dart';

/// Centered category picker dialog — opens in the middle of the screen like the
/// time picker. Returns the chosen key (or null if dismissed).
Future<String?> pickCategory(
    BuildContext context, List<CategoryDef> categories, String? currentKey) {
  final l = AppL10n.of(context);
  return showDialog<String>(
    context: context,
    builder: (context) {
      final c = context.c;
      return Dialog(
        backgroundColor: c.surface,
        insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
                child: Text(l.category,
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w700)),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final cat in categories)
                      ListTile(
                        leading: Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                              color: cat.color, shape: BoxShape.circle),
                        ),
                        title: Text(cat.displayLabel(l)),
                        trailing: currentKey == cat.key
                            ? Icon(Icons.check, color: c.accentStrong)
                            : null,
                        onTap: () => Navigator.pop(context, cat.key),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      );
    },
  );
}

/// Returns minutes-from-midnight, or null if cancelled.
Future<int?> pickMinutes(BuildContext context, int initialMin) async {
  final t = await showTimePicker(
    context: context,
    initialTime: TimeOfDay(hour: initialMin ~/ 60 % 24, minute: initialMin % 60),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
      child: child!,
    ),
  );
  if (t == null) return null;
  return t.hour * 60 + t.minute;
}
