import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../state/providers.dart';
import '../theme.dart';
import '../util/time_utils.dart';

/// Horizontal day picker. Today sits a little larger; the selected day animates
/// to the centre when tapped. Past days fill green in proportion to hours
/// logged; future days are greyed and not selectable. Drag with finger or mouse
/// to move through days.
class DayScroller extends ConsumerStatefulWidget {
  const DayScroller({super.key});

  @override
  ConsumerState<DayScroller> createState() => _DayScrollerState();
}

class _DayScrollerState extends ConsumerState<DayScroller> {
  static const int _pastDays = 120;
  static const int _futureDays = 21;
  static const double _normalW = 50;
  static const double _todayW = 62;

  late final List<DateTime> _days;
  late final int _todayIndex;
  late final List<double> _starts; // left edge of each slot, content-space
  late final ScrollController _controller;
  double _viewport = 0;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final base = DateTime(now.year, now.month, now.day);
    _todayIndex = _pastDays;
    _days = List.generate(_pastDays + 1 + _futureDays,
        (i) => base.add(Duration(days: i - _pastDays)));
    _starts = [];
    var acc = 0.0;
    for (var i = 0; i < _days.length; i++) {
      _starts.add(acc);
      acc += _slotW(i);
    }
    // With the list padded by half the viewport on each side, the offset that
    // centres a slot is just its content-space centre — independent of the
    // viewport width, so we can centre today from the start without waiting for
    // layout (ListView.builder's maxScrollExtent is unreliable on frame one).
    _controller = ScrollController(
        initialScrollOffset: _starts[_todayIndex] + _slotW(_todayIndex) / 2);
  }

  static const double _margin = 2; // horizontal margin on each side of a slot
  // The slot's drawn box width.
  double _baseW(int i) => i == _todayIndex ? _todayW : _normalW;
  // The slot's full footprint (box + margins) — what centring math must use.
  double _slotW(int i) => _baseW(i) + _margin * 2;

  int _indexOf(String ds) {
    final idx = _days.indexWhere((d) => dayString(d) == ds);
    return idx < 0 ? _todayIndex : idx;
  }

  void _centerOn(int i, {required bool animate}) {
    if (!_controller.hasClients) return;
    // Padding is half the viewport on each side, so the centre offset for a
    // slot is simply its content-space centre.
    final target = (_starts[i] + _slotW(i) / 2)
        .clamp(0.0, _controller.position.maxScrollExtent);
    if (animate) {
      _controller.animateTo(target,
          duration: const Duration(milliseconds: 360), curve: Curves.easeOutCubic);
    } else {
      _controller.jumpTo(target);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final selected = ref.watch(selectedDayProvider);
    final entries = ref.watch(entriesProvider);
    ref.watch(nowMinProvider); // refresh today's fill live
    final nowMin = minutesOfDay(DateTime.now());
    final locale = Localizations.localeOf(context).toString();

    // Animate the header so the selected day glides to the centre.
    ref.listen<String>(selectedDayProvider, (_, next) {
      _centerOn(_indexOf(next), animate: true);
    });

    return LayoutBuilder(
      builder: (context, constraints) {
        _viewport = constraints.maxWidth;
        return SizedBox(
          height: 66,
          child: ScrollConfiguration(
            // Allow dragging with a mouse/trackpad too, not just touch.
            behavior: ScrollConfiguration.of(context).copyWith(
              dragDevices: {
                PointerDeviceKind.touch,
                PointerDeviceKind.mouse,
                PointerDeviceKind.trackpad,
                PointerDeviceKind.stylus,
              },
              scrollbars: false,
            ),
            child: ListView.builder(
              controller: _controller,
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: _viewport / 2),
              itemCount: _days.length,
              itemBuilder: (context, i) {
                final d = _days[i];
                final ds = dayString(d);
                final isSelected = ds == selected;
                final isToday = i == _todayIndex;
                final isFuture = i > _todayIndex;
                final total =
                    entries.totalMin(ds, isToday ? nowMin : 1440);
                final ratio = (total / 1440).clamp(0.0, 1.0);
                final fill = isFuture
                    ? c.surfaceAlt
                    : Color.lerp(c.surface, c.accent, ratio * 0.85)!;
                final showMonth = d.day == 1 || i == 0;

                final numColor = isFuture
                    ? c.inkFaint
                    : (ratio > 0.55 ? Colors.white : c.ink);

                return Opacity(
                  opacity: isFuture ? 0.5 : 1,
                  child: GestureDetector(
                    key: ValueKey('day_$ds'),
                    behavior: HitTestBehavior.opaque,
                    onTap: isFuture
                        ? null
                        : () => ref
                            .read(selectedDayProvider.notifier)
                            .state = ds,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                      width: _baseW(i),
                      margin: EdgeInsets.symmetric(
                          horizontal: _margin, vertical: isToday ? 2 : 7),
                      decoration: BoxDecoration(
                        color: fill,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected ? c.accentStrong : c.line,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (showMonth)
                            Text(
                              DateFormat.MMM(locale).format(d),
                              style: TextStyle(
                                  fontSize: 9, color: c.inkSoft),
                            ),
                          Text(
                            '${d.day}',
                            style: TextStyle(
                              fontSize: isToday ? 22 : 17,
                              fontWeight: (isSelected || isToday)
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: numColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
