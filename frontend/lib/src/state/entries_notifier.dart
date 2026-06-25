import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../data/api_client.dart';
import '../data/local_store.dart';
import '../models/category.dart';
import '../models/entry.dart';
import '../util/time_utils.dart';

/// Owns the full set of time entries. Local-first: every mutation writes the
/// cache immediately and schedules a background sync, so the UI never waits.
class EntriesNotifier extends ChangeNotifier {
  EntriesNotifier(this._store, this._api, this._tokenGetter) {
    _entries = _store.entries;
    _pendingDeletes = _store.pendingDeletes.toSet();
    normalizeForToday();
  }

  final LocalStore _store;
  final ApiClient _api;
  final String? Function() _tokenGetter;

  List<TimeEntry> _entries = [];
  Set<String> _pendingDeletes = {};
  bool _syncing = false;

  List<TimeEntry> get all => List.unmodifiable(_entries);

  static String _newId() {
    final r = Random();
    return '${DateTime.now().microsecondsSinceEpoch}-${r.nextInt(1 << 32).toRadixString(16)}';
  }

  List<TimeEntry> forDay(String day) {
    final list = _entries.where((e) => e.day == day).toList()
      ..sort((a, b) => a.startMin.compareTo(b.startMin));
    return list;
  }

  TimeEntry? runningEntry(String day) {
    for (final e in _entries) {
      if (e.day == day && e.isRunning) return e;
    }
    return null;
  }

  /// Live current focus category key for [day] (only meaningful for today).
  String? currentFocus(String day) => runningEntry(day)?.category;

  Map<String, int> sumByCategory(String day, int nowMin) {
    final map = <String, int>{};
    for (final e in forDay(day)) {
      final dur = e.durationMin(nowMin);
      if (dur <= 0) continue;
      map[e.category] = (map[e.category] ?? 0) + dur;
    }
    return map;
  }

  int totalMin(String day, int nowMin) {
    var total = 0;
    for (final e in forDay(day)) {
      total += e.durationMin(nowMin);
    }
    return total.clamp(0, 1440);
  }

  // --- Mutations ----------------------------------------------------------

  /// Switch the live focus to [category] now. Closes the running entry and
  /// opens a new one. Matches "press a button -> new time entry".
  void setFocus(String categoryKey) {
    final now = DateTime.now();
    final day = dayString(now);
    final nowMin = minutesOfDay(now);
    normalizeForToday();

    final running = runningEntry(day);
    if (running != null && running.category == categoryKey) return; // no-op

    if (running != null) {
      if (nowMin <= running.startMin) {
        // Same minute: just relabel the running entry, no zero-length segment.
        _replace(running.copyWith(category: categoryKey));
        _afterMutation();
        return;
      }
      _replace(running.copyWith(endMin: nowMin));
    }
    _entries.add(TimeEntry(
      clientId: _newId(),
      day: day,
      category: categoryKey,
      startMin: nowMin,
      endMin: null,
    ));
    _afterMutation();
  }

  /// Manually add a historical entry (from the "change history" form).
  void addManual(String day, String categoryKey, int startMin, int endMin) {
    _entries.add(TimeEntry(
      clientId: _newId(),
      day: day,
      category: categoryKey,
      startMin: startMin,
      endMin: endMin,
    ));
    _afterMutation();
  }

  void updateEntry(String clientId,
      {String? category, int? startMin, int? endMin, bool push = true}) {
    final idx = _entries.indexWhere((e) => e.clientId == clientId);
    if (idx < 0) return;
    final e = _entries[idx];
    // endMin is only changed when explicitly provided (null = leave untouched,
    // so a category/start edit never accidentally reopens a closed entry).
    _entries[idx] = endMin == null
        ? e.copyWith(category: category, startMin: startMin)
        : e.copyWith(category: category, startMin: startMin, endMin: endMin);
    _afterMutation(push: push);
  }

  /// Find the contiguous handoff entry-pair where [aKey] hands off to [bKey]
  /// (a-entry ends exactly where a b-entry starts). Returns their client ids
  /// and the shared boundary minute, or null if there's no clean handoff.
  ({String aId, String bId, int boundary, int minB, int maxB})? handoff(
      String day, String aKey, String bKey, int nowMin) {
    final list = forDay(day);
    for (final a in list) {
      if (a.category != aKey || a.isRunning) continue;
      for (final b in list) {
        if (b.category != bKey) continue;
        if (b.startMin == a.endMin) {
          final maxB = (b.endMin ?? nowMin) - 1;
          return (
            aId: a.clientId,
            bId: b.clientId,
            boundary: a.endMin!,
            minB: a.startMin + 1,
            maxB: maxB,
          );
        }
      }
    }
    return null;
  }

  void moveHandoff(String aId, String bId, int newBoundary, {bool push = true}) {
    updateEntry(aId, endMin: newBoundary, push: false);
    updateEntry(bId, startMin: newBoundary, push: push);
  }

  void deleteEntry(String clientId) {
    _entries.removeWhere((e) => e.clientId == clientId);
    _pendingDeletes.add(clientId);
    _afterMutation();
  }

  /// Ensure the day rolls into a fresh Sleep focus at 00:00, and that today
  /// has a starting focus. Safe to call repeatedly (idempotent).
  void normalizeForToday() {
    final now = DateTime.now();
    final today = dayString(now);
    var changed = false;

    // Close any running entry left open on a previous day at its day end.
    for (var i = 0; i < _entries.length; i++) {
      final e = _entries[i];
      if (e.isRunning && e.day != today) {
        _entries[i] = e.copyWith(endMin: 1440);
        changed = true;
      }
    }

    // If today has no entries at all, start the day asleep (focus from 00:00).
    final hasToday = _entries.any((e) => e.day == today);
    if (!hasToday) {
      _entries.add(TimeEntry(
        clientId: _newId(),
        day: today,
        category: kDefaultCategoryKey,
        startMin: 0,
        endMin: null,
      ));
      changed = true;
    }

    if (changed) {
      _persist();
      notifyListeners();
      unawaited(pushSync());
    }
  }

  // --- internals ----------------------------------------------------------

  void _replace(TimeEntry updated) {
    final idx = _entries.indexWhere((e) => e.clientId == updated.clientId);
    if (idx >= 0) _entries[idx] = updated;
  }

  void _afterMutation({bool push = true}) {
    _persist();
    notifyListeners();
    if (push) unawaited(pushSync());
  }

  void _persist() {
    _store.setEntries(_entries);
    _store.setPendingDeletes(_pendingDeletes.toList());
  }

  // --- Sync ---------------------------------------------------------------

  /// Push local state to the server and merge the authoritative result back.
  Future<void> pushSync() async {
    final token = _tokenGetter();
    if (token == null || _syncing) return;
    _syncing = true;
    try {
      final upserts = _entries.toList();
      final deletes = _pendingDeletes.toList();
      final server = await _api.sync(token, upserts, deletes);
      _entries = server;
      _pendingDeletes.clear();
      normalizeForTodayQuiet();
      _persist();
      notifyListeners();
    } catch (_) {
      // Offline or transient error: keep local state; try again later.
    } finally {
      _syncing = false;
    }
  }

  /// Like normalizeForToday but without re-triggering a sync (used post-sync).
  void normalizeForTodayQuiet() {
    final now = DateTime.now();
    final today = dayString(now);
    for (var i = 0; i < _entries.length; i++) {
      final e = _entries[i];
      if (e.isRunning && e.day != today) {
        _entries[i] = e.copyWith(endMin: 1440);
      }
    }
    if (!_entries.any((e) => e.day == today)) {
      _entries.add(TimeEntry(
        clientId: _newId(),
        day: today,
        category: kDefaultCategoryKey,
        startMin: 0,
        endMin: null,
      ));
    }
  }

  Future<void> pullFromServer() async {
    final token = _tokenGetter();
    if (token == null) return;
    try {
      final server = await _api.listEntries(token);
      _entries = server;
      _pendingDeletes.clear();
      normalizeForTodayQuiet();
      _persist();
      notifyListeners();
    } catch (_) {}
  }

  void resetLocal() {
    _entries = [];
    _pendingDeletes = {};
    _persist();
    notifyListeners();
  }
}
