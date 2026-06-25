import 'package:flutter/foundation.dart';

import '../data/api_client.dart';
import '../data/local_store.dart';
import '../models/user.dart';

enum AuthStatus { unknown, unauthenticated, needsVerification, authenticated }

class AuthNotifier extends ChangeNotifier {
  AuthNotifier(this._store, this._api) {
    final token = _store.token;
    final user = _store.user;
    if (token != null && user != null) {
      _token = token;
      _user = user;
      _status = AuthStatus.authenticated;
    } else {
      _status = AuthStatus.unauthenticated;
    }
  }

  final LocalStore _store;
  final ApiClient _api;

  AuthStatus _status = AuthStatus.unknown;
  String? _token;
  AppUser? _user;
  String? _pendingEmail;

  AuthStatus get status => _status;
  String? get token => _token;
  AppUser? get user => _user;
  String? get pendingEmail => _pendingEmail;

  Future<void> register(String email, String password, String name) async {
    await _api.register(email.trim(), password, name.trim());
    _pendingEmail = email.trim();
    _status = AuthStatus.needsVerification;
    notifyListeners();
  }

  Future<void> verify(String email, String code) async {
    final res = await _api.verify(email.trim(), code.trim());
    await _onAuthenticated(res);
  }

  /// Returns true if logged in; throws ApiException(403) -> needsVerification.
  Future<void> login(String email, String password) async {
    try {
      final res = await _api.login(email.trim(), password);
      await _onAuthenticated(res);
    } on ApiException catch (e) {
      if (e.statusCode == 403) {
        _pendingEmail = email.trim();
        _status = AuthStatus.needsVerification;
        notifyListeners();
      }
      rethrow;
    }
  }

  Future<void> resend(String email) => _api.resend(email.trim());

  Future<void> _onAuthenticated(AuthResult res) async {
    _token = res.token;
    _user = res.user;
    _pendingEmail = null;
    _status = AuthStatus.authenticated;
    await _store.setToken(res.token);
    await _store.setUser(res.user);
    notifyListeners();
  }

  void backToLogin() {
    _status = AuthStatus.unauthenticated;
    _pendingEmail = null;
    notifyListeners();
  }

  Future<void> logout() async {
    _token = null;
    _user = null;
    _pendingEmail = null;
    _status = AuthStatus.unauthenticated;
    await _store.clearSession();
    notifyListeners();
  }

  Future<void> updateSettings(
      {String? name, String? timezone, String? language}) async {
    if (_token == null) return;
    final updated = await _api.updateMe(_token!,
        name: name, timezone: timezone, language: language);
    _user = updated;
    await _store.setUser(updated);
    notifyListeners();
  }

  Future<void> changePassword(String current, String next) async {
    if (_token == null) return;
    await _api.changePassword(_token!, current, next);
  }

  /// Refresh the user record from the server (best-effort).
  Future<void> refreshMe() async {
    if (_token == null) return;
    try {
      final me = await _api.getMe(_token!);
      _user = me;
      await _store.setUser(me);
      notifyListeners();
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        await logout();
      }
    } catch (_) {}
  }
}
