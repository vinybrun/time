import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../state/providers.dart';
import '../theme.dart';
import '../util/time_utils.dart';

/// One button per category. The running focus is highlighted; tapping a button
/// switches the live focus and opens a new entry.
class FocusButtons extends ConsumerWidget {
  const FocusButtons({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final entries = ref.watch(entriesProvider);
    final cats = ref.watch(categoriesProvider);
    ref.watch(nowMinProvider);
    final todayStr = today();
    final selected = ref.watch(selectedDayProvider);
    final isToday = selected == todayStr;
    final current = entries.currentFocus(todayStr);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        for (final cat in cats.enabled)
          _FocusChip(
            key: ValueKey('focus_${cat.key}'),
            label: cat.displayLabel(l),
            color: cat.color,
            active: isToday && current == cat.key,
            onTap: () {
              // Switching focus always operates on today.
              if (!isToday) {
                ref.read(selectedDayProvider.notifier).state = todayStr;
              }
              ref.read(entriesProvider).setFocus(cat.key);
            },
          ),
      ],
    );
  }
}

class _FocusChip extends StatelessWidget {
  const _FocusChip({
    super.key,
    required this.label,
    required this.color,
    required this.active,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? color : context.c.surface,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: active ? color : context.c.line,
              width: active ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 11,
                height: 11,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: active
                      ? Border.all(color: Colors.white70, width: 1.5)
                      : null,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  color: active
                      ? (color.computeLuminance() > 0.6
                          ? const Color(0xFF3A372F)
                          : Colors.white)
                      : context.c.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
