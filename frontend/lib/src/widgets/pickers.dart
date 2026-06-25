import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../models/category.dart';
import '../theme.dart';

/// Modal category picker — works the same on mobile and web (a dropdown is
/// awkward on touch, a sheet is one tap and fully legible). Returns the key.
Future<String?> pickCategory(
    BuildContext context, List<CategoryDef> categories, String? currentKey) {
  final l = AppL10n.of(context);
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.line,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(l.category,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600)),
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
                          ? const Icon(Icons.check,
                              color: AppColors.accentStrong)
                          : null,
                      onTap: () => Navigator.pop(context, cat.key),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
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
