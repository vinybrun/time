import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../models/category.dart';
import '../state/providers.dart';
import '../theme.dart';

/// A friendly palette for category colours (no full colour wheel — keep it calm).
const List<int> _palette = [
  0xFF4F7CAC, 0xFF6FB1E0, 0xFF45B69C, 0xFF7FA650,
  0xFFC58940, 0xFFE3866B, 0xFF8E6BBF, 0xFFB45B8F,
  0xFFA8A29A, 0xFF5B8C6E, 0xFFD8A24A, 0xFF7A8CA3,
];

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppL10n.of(context);
    final cats = ref.watch(categoriesProvider);
    final notifier = ref.read(categoriesProvider);
    final list = cats.all;

    return Scaffold(
      appBar: AppBar(title: Text(l.categories)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                children: [
                  for (final c in list)
                    _CategoryTile(def: c, notifier: notifier),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      side: BorderSide(color: context.c.line),
                      foregroundColor: context.c.accentStrong,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () => _addCategory(context, notifier),
                    icon: const Icon(Icons.add),
                    label: Text(l.addCategory),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => notifier.resetToDefaults(),
                    child: Text(l.resetToDefaults),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addCategory(BuildContext context, notifier) async {
    final l = AppL10n.of(context);
    final controller = TextEditingController();
    int color = _palette[0];
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(l.addCategory),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(labelText: l.categoryName),
              ),
              const SizedBox(height: 16),
              _PaletteRow(
                selected: color,
                onPick: (c) => setState(() => color = c),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(l.cancel)),
            FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(l.add)),
          ],
        ),
      ),
    );
    if (result == true && controller.text.trim().isNotEmpty) {
      notifier.addCustom(controller.text.trim(), color);
    }
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.def, required this.notifier});
  final CategoryDef def;
  final dynamic notifier;

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: context.c.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.c.line),
      ),
      child: Row(
        children: [
          // Colour swatch -> recolor.
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => _recolor(context),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: def.color,
                  shape: BoxShape.circle,
                  border: Border.all(color: context.c.line),
                ),
              ),
            ),
          ),
          // Label -> rename.
          Expanded(
            child: InkWell(
              onTap: () => _rename(context),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Text(
                  def.displayLabel(l),
                  style: TextStyle(
                    fontSize: 15,
                    color: def.enabled ? context.c.ink : context.c.inkFaint,
                  ),
                ),
              ),
            ),
          ),
          if (!def.native)
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              color: context.c.inkFaint,
              onPressed: () => notifier.remove(def.key),
              tooltip: l.delete,
            ),
          Switch(
            value: def.enabled,
            activeTrackColor: context.c.accentStrong,
            onChanged: (v) => notifier.update(def.key, enabled: v),
          ),
        ],
      ),
    );
  }

  Future<void> _recolor(BuildContext context) async {
    final l = AppL10n.of(context);
    final picked = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.color),
        content: _PaletteRow(
          selected: def.color.toARGB32(),
          onPick: (c) => Navigator.pop(context, c),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l.cancel)),
        ],
      ),
    );
    if (picked != null) notifier.update(def.key, color: picked);
  }

  Future<void> _rename(BuildContext context) async {
    final l = AppL10n.of(context);
    final controller = TextEditingController(text: def.displayLabel(l));
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.rename),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(labelText: l.categoryName),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l.cancel)),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l.save)),
        ],
      ),
    );
    if (ok == true) {
      notifier.update(def.key, label: controller.text.trim());
    }
  }
}

class _PaletteRow extends StatelessWidget {
  const _PaletteRow({required this.selected, required this.onPick});
  final int selected;
  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final c in _palette)
          GestureDetector(
            onTap: () => onPick(c),
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Color(c),
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected == c ? context.c.ink : context.c.line,
                  width: selected == c ? 3 : 1,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
