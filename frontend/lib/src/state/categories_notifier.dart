import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../data/local_store.dart';
import '../models/category.dart';

/// Owns the user's category registry (native built-ins + custom). Local-first:
/// changes persist immediately and push to the server in the background.
class CategoriesNotifier extends ChangeNotifier {
  CategoriesNotifier(this._store, this._push) {
    _cats = _store.categories ?? defaultCategories();
  }

  final LocalStore _store;
  final Future<void> Function(List<CategoryDef>) _push;

  late List<CategoryDef> _cats;

  List<CategoryDef> get all {
    final list = [..._cats]..sort((a, b) => a.order.compareTo(b.order));
    return list;
  }

  List<CategoryDef> get enabled => all.where((c) => c.enabled).toList();

  /// Resolve a key to a def, falling back for unknown/deleted categories.
  CategoryDef resolve(String key) {
    for (final c in _cats) {
      if (c.key == key) return c;
    }
    if (kNativeColors.containsKey(key)) {
      return CategoryDef(
          key: key, color: Color(kNativeColors[key]!), native: true);
    }
    return unknownCategory(key);
  }

  /// Replace the whole list (used when loading from the server).
  void load(List<CategoryDef> cats, {bool push = false}) {
    _cats = cats;
    _store.setCategories(_cats);
    notifyListeners();
    if (push) unawaited(_push(_cats));
  }

  void update(String key,
      {String? label, int? color, bool? enabled}) {
    final i = _cats.indexWhere((c) => c.key == key);
    if (i < 0) return;
    _cats[i] = _cats[i].copyWith(
      label: label,
      color: color == null ? null : Color(color),
      enabled: enabled,
    );
    _commit();
  }

  CategoryDef addCustom(String label, int color) {
    final key = 'custom_${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}'
        '${Random().nextInt(99)}';
    final def = CategoryDef(
      key: key,
      label: label,
      color: Color(color),
      native: false,
      enabled: true,
      order: (_cats.map((c) => c.order).fold<int>(-1, max)) + 1,
    );
    _cats.add(def);
    _commit();
    return def;
  }

  /// Native categories can only be disabled; custom categories can be removed.
  void remove(String key) {
    _cats.removeWhere((c) => c.key == key && !c.native);
    _commit();
  }

  void reorder(List<String> keysInOrder) {
    for (var i = 0; i < keysInOrder.length; i++) {
      final idx = _cats.indexWhere((c) => c.key == keysInOrder[i]);
      if (idx >= 0) _cats[idx] = _cats[idx].copyWith(order: i);
    }
    _commit();
  }

  void resetToDefaults() {
    _cats = defaultCategories();
    _commit();
  }

  void _commit() {
    _store.setCategories(_cats);
    notifyListeners();
    unawaited(_push(_cats));
  }
}
