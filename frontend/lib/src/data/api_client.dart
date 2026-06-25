import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/category.dart';
import '../models/entry.dart';
import '../models/user.dart';

/// Compile-time API base. Override with:
///   --dart-define=API_BASE_URL=https://time.sovereinia.org
const String kApiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:8799',
);

class ApiException implements Exception {
  ApiException(this.statusCode, this.detail);
  final int statusCode;
  final String detail;
  @override
  String toString() => 'ApiException($statusCode): $detail';
}

class AuthResult {
  AuthResult(this.token, this.user);
  final String token;
  final AppUser user;
}

class ApiClient {
  ApiClient({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        baseUrl = baseUrl ?? kApiBaseUrl;

  final http.Client _client;
  final String baseUrl;

  Uri _u(String path) => Uri.parse('$baseUrl/api/v1$path');

  Map<String, String> _headers(String? token) => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  Future<dynamic> _decode(http.Response r) async {
    final body = r.body.isEmpty ? null : jsonDecode(r.body);
    if (r.statusCode >= 200 && r.statusCode < 300) return body;
    final detail = (body is Map && body['detail'] != null)
        ? body['detail'].toString()
        : 'HTTP ${r.statusCode}';
    throw ApiException(r.statusCode, detail);
  }

  // --- Auth ---------------------------------------------------------------

  Future<void> register(String email, String password, String name) async {
    final r = await _client.post(_u('/auth/register'),
        headers: _headers(null),
        body: jsonEncode({'email': email, 'password': password, 'name': name}));
    await _decode(r);
  }

  Future<void> resend(String email) async {
    final r = await _client.post(_u('/auth/resend'),
        headers: _headers(null), body: jsonEncode({'email': email}));
    await _decode(r);
  }

  Future<AuthResult> verify(String email, String code) async {
    final r = await _client.post(_u('/auth/verify'),
        headers: _headers(null),
        body: jsonEncode({'email': email, 'code': code}));
    final body = await _decode(r) as Map<String, dynamic>;
    return AuthResult(body['access_token'] as String,
        AppUser.fromJson(body['user'] as Map<String, dynamic>));
  }

  Future<void> forgotPassword(String email) async {
    final r = await _client.post(_u('/auth/forgot-password'),
        headers: _headers(null), body: jsonEncode({'email': email}));
    await _decode(r);
  }

  Future<AuthResult> resetPassword(
      String email, String code, String newPassword) async {
    final r = await _client.post(_u('/auth/reset-password'),
        headers: _headers(null),
        body: jsonEncode(
            {'email': email, 'code': code, 'new_password': newPassword}));
    final body = await _decode(r) as Map<String, dynamic>;
    return AuthResult(body['access_token'] as String,
        AppUser.fromJson(body['user'] as Map<String, dynamic>));
  }

  Future<AuthResult> login(String email, String password) async {
    final r = await _client.post(_u('/auth/login'),
        headers: _headers(null),
        body: jsonEncode({'email': email, 'password': password}));
    final body = await _decode(r) as Map<String, dynamic>;
    return AuthResult(body['access_token'] as String,
        AppUser.fromJson(body['user'] as Map<String, dynamic>));
  }

  // --- Me -----------------------------------------------------------------

  Future<AppUser> getMe(String token) async {
    final r = await _client.get(_u('/me'), headers: _headers(token));
    return AppUser.fromJson(await _decode(r) as Map<String, dynamic>);
  }

  Future<AppUser> updateMe(String token,
      {String? name,
      String? timezone,
      String? language,
      List<CategoryDef>? categories}) async {
    final r = await _client.patch(_u('/me'),
        headers: _headers(token),
        body: jsonEncode({
          if (name != null) 'name': name,
          if (timezone != null) 'timezone': timezone,
          if (language != null) 'language': language,
          if (categories != null)
            'categories': categories.map((c) => c.toJson()).toList(),
        }));
    return AppUser.fromJson(await _decode(r) as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> exportData(String token) async {
    final r = await _client.get(_u('/me/export'), headers: _headers(token));
    return await _decode(r) as Map<String, dynamic>;
  }

  Future<void> deleteAccount(String token) async {
    final r = await _client.delete(_u('/me'), headers: _headers(token));
    await _decode(r);
  }

  Future<void> changePassword(
      String token, String currentPassword, String newPassword) async {
    final r = await _client.post(_u('/me/password'),
        headers: _headers(token),
        body: jsonEncode({
          'current_password': currentPassword,
          'new_password': newPassword,
        }));
    await _decode(r);
  }

  // --- Entries ------------------------------------------------------------

  Future<List<TimeEntry>> listEntries(String token, {String? day}) async {
    final uri = day == null ? _u('/entries') : _u('/entries').replace(
        queryParameters: {'day': day});
    final r = await _client.get(uri, headers: _headers(token));
    final list = await _decode(r) as List;
    return list
        .map((e) => TimeEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<TimeEntry>> sync(
      String token, List<TimeEntry> upserts, List<String> deletes) async {
    final r = await _client.post(_u('/entries/sync'),
        headers: _headers(token),
        body: jsonEncode({
          'upserts': upserts.map((e) => e.toJson()).toList(),
          'deletes': deletes,
        }));
    final list = await _decode(r) as List;
    return list
        .map((e) => TimeEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
