import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/entry.dart';
import '../models/user.dart';

/// Thin wrapper over shared_preferences for instant local-first reads/writes.
class LocalStore {
  LocalStore(this._prefs);

  final SharedPreferences _prefs;

  static const _kToken = 'auth_token';
  static const _kUser = 'auth_user';
  static const _kEntries = 'entries_cache';
  static const _kPendingDeletes = 'pending_deletes';
  static const _kLocaleOverride = 'locale_override';

  static Future<LocalStore> create() async =>
      LocalStore(await SharedPreferences.getInstance());

  // Auth token
  String? get token => _prefs.getString(_kToken);
  Future<void> setToken(String? v) async {
    if (v == null) {
      await _prefs.remove(_kToken);
    } else {
      await _prefs.setString(_kToken, v);
    }
  }

  // User
  AppUser? get user {
    final s = _prefs.getString(_kUser);
    if (s == null) return null;
    try {
      return AppUser.fromJson(jsonDecode(s) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> setUser(AppUser? u) async {
    if (u == null) {
      await _prefs.remove(_kUser);
    } else {
      await _prefs.setString(_kUser, jsonEncode(u.toJson()));
    }
  }

  // Entries cache (full set)
  List<TimeEntry> get entries {
    final s = _prefs.getString(_kEntries);
    if (s == null) return [];
    try {
      final list = jsonDecode(s) as List;
      return list
          .map((e) => TimeEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> setEntries(List<TimeEntry> entries) async {
    await _prefs.setString(
        _kEntries, jsonEncode(entries.map((e) => e.toJson()).toList()));
  }

  // Pending deletes awaiting sync
  List<String> get pendingDeletes =>
      _prefs.getStringList(_kPendingDeletes) ?? [];

  Future<void> setPendingDeletes(List<String> ids) async {
    await _prefs.setStringList(_kPendingDeletes, ids);
  }

  // Locale override (null = automatic)
  String? get localeOverride => _prefs.getString(_kLocaleOverride);
  Future<void> setLocaleOverride(String? code) async {
    if (code == null) {
      await _prefs.remove(_kLocaleOverride);
    } else {
      await _prefs.setString(_kLocaleOverride, code);
    }
  }

  Future<void> clearSession() async {
    await _prefs.remove(_kToken);
    await _prefs.remove(_kUser);
    await _prefs.remove(_kEntries);
    await _prefs.remove(_kPendingDeletes);
  }
}
