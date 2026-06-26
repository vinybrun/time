import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../state/providers.dart';
import '../theme.dart';
import '../util/time_utils.dart';
import '../widgets/day_donut.dart';
import '../widgets/day_scroller.dart';
import '../widgets/focus_buttons.dart';
import '../widgets/footer.dart';
import '../widgets/history_section.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Pull authoritative state in the background; UI already shows the cache.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _loadCategoriesFromUser();
      ref.read(entriesProvider).pushSync();
      await ref.read(authProvider).refreshMe();
      _loadCategoriesFromUser();
    });
  }

  void _loadCategoriesFromUser() {
    final cats = ref.read(authProvider).user?.categories;
    if (cats != null && cats.isNotEmpty) {
      ref.read(categoriesProvider).load(cats);
    }
  }

  // Drag-to-edit handoff state.
  String? _dragA, _dragB;
  int _dragOrigB = 0, _dragMinB = 0, _dragMaxB = 1440;

  void _onDragStart(List<DonutSegment> segments, String day, int leftIndex) {
    _dragA = _dragB = null;
    if (leftIndex < 0 || leftIndex + 1 >= segments.length) return;
    final aKey = segments[leftIndex].def.key;
    final bKey = segments[leftIndex + 1].def.key;
    final nowMin = minutesOfDay(DateTime.now());
    final h = ref.read(entriesProvider).handoff(day, aKey, bKey, nowMin);
    if (h == null) return;
    _dragA = h.aId;
    _dragB = h.bId;
    _dragOrigB = h.boundary;
    _dragMinB = h.minB;
    _dragMaxB = h.maxB;
  }

  void _onDragUpdate(int deltaMin) {
    if (_dragA == null || _dragB == null) return;
    final newB = (_dragOrigB + deltaMin).clamp(_dragMinB, _dragMaxB);
    ref.read(entriesProvider).moveHandoff(_dragA!, _dragB!, newB, push: false);
  }

  void _onDragEnd() {
    if (_dragA != null) ref.read(entriesProvider).pushSync();
    _dragA = _dragB = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(entriesProvider).normalizeForToday();
      ref.read(entriesProvider).pushSync();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final day = ref.watch(selectedDayProvider);
    final entries = ref.watch(entriesProvider);
    final cats = ref.watch(categoriesProvider);
    ref.watch(nowMinProvider);
    final todayStr = today();
    final nowMin = minutesOfDay(DateTime.now());
    final refMin = day == todayStr ? nowMin : 1440;

    // Donut segments ordered by each category's FIRST entry of the day
    // (the "where is your focus" buttons keep their fixed order instead).
    final dayEntries = entries.forDay(day); // sorted by start time
    final order = <String>[];
    final sums = <String, int>{};
    for (final e in dayEntries) {
      sums[e.category] = (sums[e.category] ?? 0) + e.durationMin(refMin);
      if (!order.contains(e.category)) order.add(e.category);
    }
    final segments = [
      for (final key in order)
        if ((sums[key] ?? 0) > 0) DonutSegment(cats.resolve(key), sums[key]!),
    ];
    final total = entries.totalMin(day, refMin);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              automaticallyImplyLeading: false,
              backgroundColor: context.c.background,
              titleSpacing: 0,
              title: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: DayScroller(),
              ),
              toolbarHeight: 72,
            ),
            SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 8),
                      _SectionTitle(l.focusTitle),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: FocusButtons(),
                      ),
                      const SizedBox(height: 18),
                      DayDonut(
                        segments: segments,
                        totalMin: total,
                        centerLabel: day == todayStr
                            ? l.today
                            : _dayNumber(day),
                        onBoundaryDragStart: (i) =>
                            _onDragStart(segments, day, i),
                        onBoundaryDragUpdate: _onDragUpdate,
                        onBoundaryDragEnd: _onDragEnd,
                      ),
                      const SizedBox(height: 12),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: HistorySection(),
                      ),
                      const SizedBox(height: 8),
                      const AppFooter(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _dayNumber(String day) {
    final d = parseDay(day);
    return '${d.day}';
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
            fontSize: 16, fontWeight: FontWeight.w700, color: context.c.ink),
      ),
    );
  }
}
