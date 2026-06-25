import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../state/providers.dart';
import '../theme.dart';
import '../util/time_utils.dart';

/// Horizontal day picker. Each day fills green in proportion to hours logged
/// (fully green only at 24h). Defaults to today; scroll to change day.
class DayScroller extends ConsumerStatefulWidget {
  const DayScroller({super.key});

  @override
  ConsumerState<DayScroller> createState() => _DayScrollerState();
}

class _DayScrollerState extends ConsumerState<DayScroller> {
  static const int _pastDays = 120;
  static const double _itemWidth = 50;
  late final List<DateTime> _days;
  late final ScrollController _controller;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: _pastDays));
    _days = List.generate(
        _pastDays + 1, (i) => start.add(Duration(days: i)));
    _controller = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelected());
  }

  void _scrollToSelected() {
    if (!_controller.hasClients) return;
    final sel = ref.read(selectedDayProvider);
    final idx = _days.indexWhere((d) => dayString(d) == sel);
    if (idx < 0) return;
    final target = (idx * _itemWidth) -
        (_controller.position.viewportDimension / 2) +
        (_itemWidth / 2);
    _controller.jumpTo(target.clamp(
        0, _controller.position.maxScrollExtent));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selected = ref.watch(selectedDayProvider);
    final entries = ref.watch(entriesProvider);
    ref.watch(nowMinProvider); // refresh today's fill live
    final nowMin = minutesOfDay(DateTime.now());
    final todayStr = today();
    final locale = Localizations.localeOf(context).toString();

    return SizedBox(
      height: 64,
      child: ListView.builder(
        controller: _controller,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _days.length,
        itemBuilder: (context, i) {
          final d = _days[i];
          final ds = dayString(d);
          final isSelected = ds == selected;
          final isToday = ds == todayStr;
          final total = entries.totalMin(ds, ds == todayStr ? nowMin : 1440);
          final ratio = (total / 1440).clamp(0.0, 1.0);
          final fill = Color.lerp(
              AppColors.surface, AppColors.accent, ratio * 0.85)!;
          final showMonth = d.day == 1 || i == 0;

          return GestureDetector(
            key: ValueKey('day_$ds'),
            onTap: () =>
                ref.read(selectedDayProvider.notifier).state = ds,
            child: Container(
              width: _itemWidth,
              margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
              decoration: BoxDecoration(
                color: fill,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected
                      ? AppColors.accentStrong
                      : AppColors.line,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (showMonth)
                    Text(
                      DateFormat.MMM(locale).format(d),
                      style: const TextStyle(
                          fontSize: 9, color: AppColors.inkSoft),
                    ),
                  Text(
                    '${d.day}',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: ratio > 0.55 ? Colors.white : AppColors.ink,
                    ),
                  ),
                  if (isToday)
                    Container(
                      width: 5,
                      height: 5,
                      margin: const EdgeInsets.only(top: 2),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.accentStrong
                            : AppColors.inkSoft,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
