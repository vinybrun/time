import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/api_client.dart';
import '../data/local_store.dart';
import '../theme.dart';
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

// --- Theme -----------------------------------------------------------------

enum ThemeChoice { offWhite, dark, circadian }

ThemeChoice _themeFromCode(String? code) => switch (code) {
      'dark' => ThemeChoice.dark,
      'circadian' => ThemeChoice.circadian,
      _ => ThemeChoice.offWhite,
    };

String themeCode(ThemeChoice c) => switch (c) {
      ThemeChoice.dark => 'dark',
      ThemeChoice.circadian => 'circadian',
      ThemeChoice.offWhite => 'offwhite',
    };

/// The chosen theme, persisted locally (a device preference, not synced).
final themeChoiceProvider =
    StateNotifierProvider<ThemeChoiceNotifier, ThemeChoice>((ref) {
  return ThemeChoiceNotifier(ref.watch(localStoreProvider));
});

class ThemeChoiceNotifier extends StateNotifier<ThemeChoice> {
  ThemeChoiceNotifier(this._store) : super(_themeFromCode(_store.themeChoice));
  final LocalStore _store;

  Future<void> set(ThemeChoice choice) async {
    await _store.setThemeChoice(themeCode(choice));
    state = choice;
  }
}

/// Ticks every minute (only while listened) so the circadian palette drifts
/// with the local clock. Kept separate from [nowMinProvider] so it doesn't pull
/// in the entries graph before the user is even authenticated.
final clockProvider = StreamProvider.autoDispose<DateTime>((ref) async* {
  yield DateTime.now();
  while (true) {
    await Future<void>.delayed(const Duration(minutes: 1));
    yield DateTime.now();
  }
});

/// The active palette for the chosen theme. For circadian it depends on the
/// local clock and so changes through the day.
final appPaletteProvider = Provider<AppPalette>((ref) {
  switch (ref.watch(themeChoiceProvider)) {
    case ThemeChoice.offWhite:
      return kOffWhitePalette;
    case ThemeChoice.dark:
      return kDarkPalette;
    case ThemeChoice.circadian:
      final now = ref.watch(clockProvider).value ?? DateTime.now();
      return circadianPaletteAt(now);
  }
});

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
