import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../models/category.dart';
import '../models/entry.dart';
import '../state/categories_notifier.dart';
import '../state/providers.dart';
import '../theme.dart';
import '../util/time_utils.dart';
import 'pickers.dart';

class HistorySection extends ConsumerStatefulWidget {
  const HistorySection({super.key});

  @override
  ConsumerState<HistorySection> createState() => _HistorySectionState();
}

class _HistorySectionState extends ConsumerState<HistorySection> {
  String? _draftCatKey;
  int _draftStart = 9 * 60;
  int _draftEnd = 10 * 60;

  String _draftKey(CategoriesNotifier cats) {
    final enabled = cats.enabled;
    if (_draftCatKey != null && enabled.any((c) => c.key == _draftCatKey)) {
      return _draftCatKey!;
    }
    return enabled.isNotEmpty ? enabled.first.key : kDefaultCategoryKey;
  }

  Future<void> _pickDraftCat(CategoriesNotifier cats) async {
    final k = await pickCategory(context, cats.enabled, _draftKey(cats));
    if (k != null) setState(() => _draftCatKey = k);
  }

  Future<void> _pickDraftStart() async {
    final m = await pickMinutes(context, _draftStart);
    if (m != null) setState(() => _draftStart = m);
  }

  Future<void> _pickDraftEnd() async {
    final m = await pickMinutes(context, _draftEnd);
    if (m != null) setState(() => _draftEnd = m);
  }

  void _add(CategoriesNotifier cats) {
    final l = AppL10n.of(context);
    if (_draftEnd <= _draftStart) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.endTime)));
      return;
    }
    final day = ref.read(selectedDayProvider);
    ref.read(entriesProvider).addManual(day, _draftKey(cats), _draftStart, _draftEnd);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final day = ref.watch(selectedDayProvider);
    final entries = ref.watch(entriesProvider);
    final cats = ref.watch(categoriesProvider);
    ref.watch(nowMinProvider);
    final rows = entries.forDay(day);
    final draft = cats.resolve(_draftKey(cats));

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.historyTitle,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(l.entryOverlapNote,
                style:
                    const TextStyle(fontSize: 12, color: AppColors.inkFaint)),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  flex: 4,
                  child: _Field(
                    label: l.category,
                    onTap: () => _pickDraftCat(cats),
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                              color: draft.color, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(draft.displayLabel(l),
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13)),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  flex: 2,
                  child: _Field(
                    label: l.startTime,
                    onTap: _pickDraftStart,
                    child: Text(formatMinutes(_draftStart),
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.visible,
                        style: const TextStyle(fontSize: 13)),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  flex: 2,
                  child: _Field(
                    label: l.endTime,
                    onTap: _pickDraftEnd,
                    child: Text(formatMinutes(_draftEnd),
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.visible,
                        style: const TextStyle(fontSize: 13)),
                  ),
                ),
                const SizedBox(width: 6),
                IconButton.filled(
                  key: const ValueKey('history_add'),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.accentStrong,
                    minimumSize: const Size(44, 44),
                  ),
                  onPressed: () => _add(cats),
                  icon: const Icon(Icons.add, color: Colors.white),
                  tooltip: l.add,
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(height: 1),
            if (rows.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(l.noEntries,
                      style: const TextStyle(color: AppColors.inkFaint)),
                ),
              )
            else
              ...rows.map((e) => _EntryRow(entry: e)),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.label, required this.onTap, required this.child});
  final String label;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style:
                    const TextStyle(fontSize: 9.5, color: AppColors.inkFaint)),
            const SizedBox(height: 2),
            child,
          ],
        ),
      ),
    );
  }
}

class _EntryRow extends ConsumerWidget {
  const _EntryRow({required this.entry});
  final TimeEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final notifier = ref.read(entriesProvider);
    final cats = ref.watch(categoriesProvider);
    final def = cats.resolve(entry.category);
    final nowMin = minutesOfDay(DateTime.now());
    final endLabel =
        entry.isRunning ? l.running : formatMinutes(entry.endMin ?? nowMin);

    Future<void> editCat() async {
      final k = await pickCategory(context, cats.enabled, entry.category);
      if (k != null) notifier.updateEntry(entry.clientId, category: k);
    }

    Future<void> editStart() async {
      final m = await pickMinutes(context, entry.startMin);
      if (m != null) notifier.updateEntry(entry.clientId, startMin: m);
    }

    Future<void> editEnd() async {
      if (entry.isRunning) return; // running entry ends "now"
      final m = await pickMinutes(context, entry.endMin ?? nowMin);
      if (m != null) notifier.updateEntry(entry.clientId, endMin: m);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: InkWell(
              onTap: editCat,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                          color: def.color, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(def.displayLabel(l),
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13.5)),
                    ),
                  ],
                ),
              ),
            ),
          ),
          _TimeCell(label: formatMinutes(entry.startMin), onTap: editStart),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 2),
            child: Text('–', style: TextStyle(color: AppColors.inkFaint)),
          ),
          _TimeCell(
            label: endLabel,
            onTap: editEnd,
            muted: entry.isRunning,
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            iconSize: 18,
            color: AppColors.inkFaint,
            onPressed: () => notifier.deleteEntry(entry.clientId),
            icon: const Icon(Icons.close),
            tooltip: l.delete,
          ),
        ],
      ),
    );
  }
}

class _TimeCell extends StatelessWidget {
  const _TimeCell(
      {required this.label, required this.onTap, this.muted = false});
  final String label;
  final VoidCallback onTap;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13.5,
            color: muted ? AppColors.accentStrong : AppColors.ink,
            fontWeight: muted ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
