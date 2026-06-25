import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/api_client.dart';
import '../data/local_store.dart';
import '../util/time_utils.dart';
import 'auth_notifier.dart';
import 'categories_notifier.dart';
import 'entries_notifier.dart';

/// Provided at app startup via ProviderScope overrides.
final localStoreProvider = Provider<LocalStore>((ref) {
  throw UnimplementedError('localStoreProvider must be overridden');
});

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

final authProvider = ChangeNotifierProvider<AuthNotifier>((ref) {
  return AuthNotifier(ref.watch(localStoreProvider), ref.watch(apiClientProvider));
});

final entriesProvider = ChangeNotifierProvider<EntriesNotifier>((ref) {
  final auth = ref.watch(authProvider);
  return EntriesNotifier(
    ref.watch(localStoreProvider),
    ref.watch(apiClientProvider),
    () => auth.token,
  );
});

final categoriesProvider = ChangeNotifierProvider<CategoriesNotifier>((ref) {
  return CategoriesNotifier(
    ref.watch(localStoreProvider),
    (cats) async {
      try {
        await ref.read(authProvider).updateSettings(categories: cats);
      } catch (_) {/* offline: local copy is kept, retried on next change */}
    },
  );
});

/// Currently selected day (YYYY-MM-DD). Defaults to today.
final selectedDayProvider = StateProvider<String>((ref) => today());

/// Locale override: null = follow system. Persisted in LocalStore.
final localeOverrideProvider =
    StateNotifierProvider<LocaleOverrideNotifier, Locale?>((ref) {
  final store = ref.watch(localStoreProvider);
  return LocaleOverrideNotifier(store);
});

class LocaleOverrideNotifier extends StateNotifier<Locale?> {
  LocaleOverrideNotifier(this._store)
      : super(_store.localeOverride == null
            ? null
            : Locale(_store.localeOverride!));
  final LocalStore _store;

  Future<void> set(String? code) async {
    await _store.setLocaleOverride(code);
    state = code == null ? null : Locale(code);
  }
}

/// Ticks every 20s with the current minute-of-day, so live running entries and
/// the day-rollover logic refresh without manual reloads.
final nowMinProvider = StreamProvider<int>((ref) {
  final entries = ref.watch(entriesProvider);
  late final StreamController<int> controller;
  Timer? timer;

  void tick() {
    entries.normalizeForToday();
    controller.add(minutesOfDay(DateTime.now()));
  }

  controller = StreamController<int>(
    onListen: () {
      tick();
      timer = Timer.periodic(const Duration(seconds: 20), (_) => tick());
    },
    onCancel: () => timer?.cancel(),
  );
  ref.onDispose(() {
    timer?.cancel();
    controller.close();
  });
  return controller.stream;
});
