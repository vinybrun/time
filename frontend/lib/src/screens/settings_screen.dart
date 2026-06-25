import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../state/providers.dart';
import '../theme.dart';
import '../util/errors.dart';
import '../util/exporter.dart';
import '../util/timezones.dart';
import 'categories_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final TextEditingController _name;
  final _currentPw = TextEditingController();
  final _newPw = TextEditingController();
  String? _tz;
  bool _busy = false;

  static const _langs = {
    'auto': 'Automatic',
    'en': 'English',
    'pt': 'Português',
    'es': 'Español',
    'fr': 'Français',
    'de': 'Deutsch',
  };

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    _name = TextEditingController(text: user?.name ?? '');
    _tz = user?.timezone ?? 'UTC';
  }

  @override
  void dispose() {
    _name.dispose();
    _currentPw.dispose();
    _newPw.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _saveProfile() async {
    final l = AppL10n.of(context);
    setState(() => _busy = true);
    try {
      await ref.read(authProvider).updateSettings(
            name: _name.text.trim(),
            timezone: _tz,
          );
      _snack(l.settingsSaved);
    } catch (e) {
      _snack(messageForError(e, l));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _changePassword() async {
    final l = AppL10n.of(context);
    if (_newPw.text.length < 8) {
      _snack(l.errorPasswordShort);
      return;
    }
    setState(() => _busy = true);
    try {
      await ref
          .read(authProvider)
          .changePassword(_currentPw.text, _newPw.text);
      _currentPw.clear();
      _newPw.clear();
      _snack(l.passwordChanged);
    } catch (e) {
      _snack(messageForError(e, l));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _export() async {
    final l = AppL10n.of(context);
    setState(() => _busy = true);
    try {
      final data = await ref.read(authProvider).exportData();
      final json = const JsonEncoder.withIndent('  ').convert(data);
      final how = await saveExport('time-export.json', json);
      _snack(how == 'download' ? l.exportedDownload : l.exportedClipboard);
    } catch (e) {
      _snack(messageForError(e, l));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _deleteAccount() async {
    final l = AppL10n.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.deleteAccount),
        content: Text(l.deleteAccountWarn),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l.deleteForever),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _busy = true);
    try {
      await ref.read(authProvider).deleteAccount();
      if (mounted) Navigator.of(context).pop(); // back to the (now) auth screen
    } catch (e) {
      _snack(messageForError(e, l));
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _setLanguage(String code) async {
    final override = ref.read(localeOverrideProvider.notifier);
    if (code == 'auto') {
      await override.set(null);
      await _trySaveLanguage('en');
    } else {
      await override.set(code);
      await _trySaveLanguage(code);
    }
  }

  Future<void> _trySaveLanguage(String code) async {
    try {
      await ref.read(authProvider).updateSettings(language: code);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final user = ref.watch(authProvider).user;
    final override = ref.watch(localeOverrideProvider);
    final currentLang = override?.languageCode ?? 'auto';
    final zones = timezoneOptions(_tz ?? 'UTC');

    return Scaffold(
      appBar: AppBar(title: Text(l.settingsTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _GroupTitle(l.account),
                  if (user != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(user.email,
                          style: const TextStyle(color: AppColors.inkSoft)),
                    ),
                  TextField(
                    controller: _name,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(labelText: l.name),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: _tz,
                    isExpanded: true,
                    decoration: InputDecoration(labelText: l.timezone),
                    items: [
                      for (final z in zones)
                        DropdownMenuItem(value: z, child: Text(z)),
                    ],
                    onChanged: (v) => setState(() => _tz = v),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: currentLang,
                    isExpanded: true,
                    decoration: InputDecoration(labelText: l.language),
                    items: [
                      for (final e in _langs.entries)
                        DropdownMenuItem(
                          value: e.key,
                          child: Text(e.key == 'auto'
                              ? l.languageAuto
                              : e.value),
                        ),
                    ],
                    onChanged: (v) {
                      if (v != null) _setLanguage(v);
                    },
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _busy ? null : _saveProfile,
                    child: Text(l.save),
                  ),
                  const SizedBox(height: 28),
                  _GroupTitle(l.changePassword),
                  TextField(
                    controller: _currentPw,
                    obscureText: true,
                    decoration:
                        InputDecoration(labelText: l.currentPassword),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _newPw,
                    obscureText: true,
                    decoration: InputDecoration(labelText: l.newPassword),
                  ),
                  const SizedBox(height: 14),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      side: const BorderSide(color: AppColors.line),
                      foregroundColor: AppColors.ink,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: _busy ? null : _changePassword,
                    child: Text(l.changePassword),
                  ),
                  const SizedBox(height: 28),
                  _GroupTitle(l.categories),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      side: const BorderSide(color: AppColors.line),
                      foregroundColor: AppColors.ink,
                      alignment: Alignment.centerLeft,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const CategoriesScreen()),
                    ),
                    icon: const Icon(Icons.palette_outlined, size: 20),
                    label: Text(l.manageCategoriesHint),
                  ),
                  const SizedBox(height: 28),
                  _GroupTitle(l.yourData),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      side: const BorderSide(color: AppColors.line),
                      foregroundColor: AppColors.ink,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: _busy ? null : _export,
                    icon: const Icon(Icons.download_outlined, size: 20),
                    label: Text(l.exportData),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      side: const BorderSide(color: AppColors.danger),
                      foregroundColor: AppColors.danger,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: _busy ? null : _deleteAccount,
                    icon: const Icon(Icons.delete_outline, size: 20),
                    label: Text(l.deleteAccount),
                  ),
                  const SizedBox(height: 28),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                        foregroundColor: AppColors.inkSoft,
                        minimumSize: const Size.fromHeight(48)),
                    onPressed: () async {
                      await ref.read(authProvider).logout();
                      if (context.mounted) Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.logout),
                    label: Text(l.logout),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GroupTitle extends StatelessWidget {
  const _GroupTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(text,
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: AppColors.inkSoft)),
    );
  }
}
