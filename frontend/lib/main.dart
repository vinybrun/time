import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'l10n/app_localizations.dart';
import 'src/data/local_store.dart';
import 'src/screens/auth_screen.dart';
import 'src/screens/home_screen.dart';
import 'src/state/auth_notifier.dart';
import 'src/state/providers.dart';
import 'src/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = await LocalStore.create();
  runApp(
    ProviderScope(
      overrides: [localStoreProvider.overrideWithValue(store)],
      child: const TimeApp(),
    ),
  );
}

class TimeApp extends ConsumerWidget {
  const TimeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final override = ref.watch(localeOverrideProvider);
    final palette = ref.watch(appPaletteProvider);
    return MaterialApp(
      title: 'Time',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(palette),
      // Cross-fade theme changes so the circadian drift is gentle, not abrupt.
      themeAnimationDuration: const Duration(milliseconds: 900),
      themeAnimationCurve: Curves.easeInOut,
      locale: override,
      localizationsDelegates: AppL10n.localizationsDelegates,
      supportedLocales: AppL10n.supportedLocales,
      home: const _Root(),
    );
  }
}

class _Root extends ConsumerWidget {
  const _Root();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    switch (auth.status) {
      case AuthStatus.authenticated:
        return const HomeScreen();
      case AuthStatus.unknown:
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      case AuthStatus.unauthenticated:
      case AuthStatus.needsVerification:
        return const AuthScreen();
    }
  }
}
