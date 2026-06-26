import 'package:flutter/material.dart';

/// The full set of semantic colors the app paints with. Lives as a
/// [ThemeExtension] so it can change at runtime (off-white, dark, or the
/// time-varying circadian theme) and every widget that reads it via
/// `context.c` rebuilds when it changes.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.brightness,
    required this.background,
    required this.surface,
    required this.surfaceAlt,
    required this.ink,
    required this.inkSoft,
    required this.inkFaint,
    required this.line,
    required this.accent,
    required this.accentStrong,
    required this.danger,
  });

  final Brightness brightness;
  final Color background;
  final Color surface;
  final Color surfaceAlt;
  final Color ink;
  final Color inkSoft;
  final Color inkFaint;
  final Color line;
  final Color accent;
  final Color accentStrong;
  final Color danger;

  @override
  AppPalette copyWith({
    Brightness? brightness,
    Color? background,
    Color? surface,
    Color? surfaceAlt,
    Color? ink,
    Color? inkSoft,
    Color? inkFaint,
    Color? line,
    Color? accent,
    Color? accentStrong,
    Color? danger,
  }) =>
      AppPalette(
        brightness: brightness ?? this.brightness,
        background: background ?? this.background,
        surface: surface ?? this.surface,
        surfaceAlt: surfaceAlt ?? this.surfaceAlt,
        ink: ink ?? this.ink,
        inkSoft: inkSoft ?? this.inkSoft,
        inkFaint: inkFaint ?? this.inkFaint,
        line: line ?? this.line,
        accent: accent ?? this.accent,
        accentStrong: accentStrong ?? this.accentStrong,
        danger: danger ?? this.danger,
      );

  @override
  bool operator ==(Object other) =>
      other is AppPalette &&
      other.brightness == brightness &&
      other.background == background &&
      other.surface == surface &&
      other.surfaceAlt == surfaceAlt &&
      other.ink == ink &&
      other.inkSoft == inkSoft &&
      other.inkFaint == inkFaint &&
      other.line == line &&
      other.accent == accent &&
      other.accentStrong == accentStrong &&
      other.danger == danger;

  @override
  int get hashCode => Object.hash(brightness, background, surface, surfaceAlt,
      ink, inkSoft, inkFaint, line, accent, accentStrong, danger);

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppPalette(
      brightness: t < 0.5 ? brightness : other.brightness,
      background: c(background, other.background),
      surface: c(surface, other.surface),
      surfaceAlt: c(surfaceAlt, other.surfaceAlt),
      ink: c(ink, other.ink),
      inkSoft: c(inkSoft, other.inkSoft),
      inkFaint: c(inkFaint, other.inkFaint),
      line: c(line, other.line),
      accent: c(accent, other.accent),
      accentStrong: c(accentStrong, other.accentStrong),
      danger: c(danger, other.danger),
    );
  }
}

/// Calm off-white "paper" — the default.
const AppPalette kOffWhitePalette = AppPalette(
  brightness: Brightness.light,
  background: Color(0xFFF7F5EF),
  surface: Color(0xFFFFFDF7),
  surfaceAlt: Color(0xFFF0EDE3),
  ink: Color(0xFF2E2B25),
  inkSoft: Color(0xFF6E695E),
  inkFaint: Color(0xFF9C968A),
  line: Color(0xFFE6E1D5),
  accent: Color(0xFF5B8C6E),
  accentStrong: Color(0xFF3F7355),
  danger: Color(0xFFB45B4F),
);

/// Restful dark gray.
const AppPalette kDarkPalette = AppPalette(
  brightness: Brightness.dark,
  background: Color(0xFF1A1A1C),
  surface: Color(0xFF242427),
  surfaceAlt: Color(0xFF2D2D31),
  ink: Color(0xFFE7E6E3),
  inkSoft: Color(0xFFA7A5A0),
  inkFaint: Color(0xFF74726D),
  line: Color(0xFF34343A),
  accent: Color(0xFF5B8C6E),
  accentStrong: Color(0xFF82B79A),
  danger: Color(0xFFCF6E62),
);

// --- Circadian -------------------------------------------------------------
// Keyframe palettes tied to the sky through the day. We lerp between the two
// surrounding keyframes, so the whole UI drifts smoothly from night → dawn →
// day → dusk → night following the user's local clock.

const AppPalette _circNight = AppPalette(
  brightness: Brightness.dark,
  background: Color(0xFF12141C),
  surface: Color(0xFF1B1E29),
  surfaceAlt: Color(0xFF232737),
  ink: Color(0xFFE9E8F0),
  inkSoft: Color(0xFFA9AEC2),
  inkFaint: Color(0xFF6B7088),
  line: Color(0xFF2C3144),
  accent: Color(0xFF5C7FB0),
  accentStrong: Color(0xFF8AA6D8),
  danger: Color(0xFFCF6E62),
);

const AppPalette _circMorning = AppPalette(
  brightness: Brightness.light,
  background: Color(0xFFF8E7DA),
  surface: Color(0xFFFEF4EC),
  surfaceAlt: Color(0xFFF2DFD0),
  ink: Color(0xFF3C2E28),
  inkSoft: Color(0xFF7E695C),
  inkFaint: Color(0xFFAD988B),
  line: Color(0xFFEBD7C6),
  accent: Color(0xFFCE8C6A),
  accentStrong: Color(0xFFB56E4C),
  danger: Color(0xFFB45B4F),
);

const AppPalette _circDay = AppPalette(
  brightness: Brightness.light,
  background: Color(0xFFE8F1F7),
  surface: Color(0xFFF6FAFD),
  surfaceAlt: Color(0xFFDCE8F0),
  ink: Color(0xFF223038),
  inkSoft: Color(0xFF596975),
  inkFaint: Color(0xFF90A0AB),
  line: Color(0xFFD0DFE9),
  accent: Color(0xFF4F90B2),
  accentStrong: Color(0xFF3B7FA4),
  danger: Color(0xFFB45B4F),
);

const AppPalette _circSunset = AppPalette(
  brightness: Brightness.light,
  background: Color(0xFFF4DDCD),
  surface: Color(0xFFFCEBDF),
  surfaceAlt: Color(0xFFEDCFBB),
  ink: Color(0xFF402E27),
  inkSoft: Color(0xFF856A5B),
  inkFaint: Color(0xFFB59A8A),
  line: Color(0xFFE9CBB6),
  accent: Color(0xFFD98A5A),
  accentStrong: Color(0xFFC56B3E),
  danger: Color(0xFFB45B4F),
);

// (hour-of-day, palette) keyframes using standard-ish sunrise ~6:30 and
// sunset ~18:30. The list is read in order; the day wraps at 24h back to 0h.
const List<(double, AppPalette)> _circKeyframes = [
  (0.0, _circNight),
  (5.0, _circNight),
  (6.5, _circMorning), // sunrise
  (8.5, _circDay),
  (16.5, _circDay),
  (18.5, _circSunset), // sunset
  (19.5, _circSunset),
  (21.0, _circNight),
  (24.0, _circNight),
];

/// The circadian palette for a given local time-of-day.
AppPalette circadianPaletteAt(DateTime localNow) {
  final h = localNow.hour + localNow.minute / 60.0;
  for (var i = 0; i < _circKeyframes.length - 1; i++) {
    final (h0, p0) = _circKeyframes[i];
    final (h1, p1) = _circKeyframes[i + 1];
    if (h >= h0 && h <= h1) {
      final t = h1 == h0 ? 0.0 : (h - h0) / (h1 - h0);
      return p0.lerp(p1, t);
    }
  }
  return _circNight;
}

/// Builds the [ThemeData] for a palette and registers the palette as an
/// extension so widgets can read it via `context.c`.
ThemeData buildTheme(AppPalette p) {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: p.accent,
      brightness: p.brightness,
      surface: p.surface,
    ).copyWith(
      primary: p.accentStrong,
      surface: p.surface,
      onSurface: p.ink,
    ),
    scaffoldBackgroundColor: p.background,
    fontFamily: 'Roboto',
    extensions: [p],
  );

  return base.copyWith(
    textTheme: base.textTheme.apply(bodyColor: p.ink, displayColor: p.ink),
    appBarTheme: AppBarTheme(
      backgroundColor: p.background,
      foregroundColor: p.ink,
      elevation: 0,
      centerTitle: true,
    ),
    cardTheme: CardThemeData(
      color: p.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: p.line),
      ),
      margin: EdgeInsets.zero,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: p.surface,
      surfaceTintColor: Colors.transparent,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: p.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: p.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: p.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: p.accentStrong, width: 1.6),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: p.accentStrong,
        foregroundColor: p.brightness == Brightness.dark ? p.ink : Colors.white,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: p.accentStrong),
    ),
    dividerTheme: DividerThemeData(color: p.line, thickness: 1),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: p.ink,
      contentTextStyle: TextStyle(color: p.background),
    ),
  );
}

/// Terse access to the active palette from any widget: `context.c.ink`.
extension PaletteContext on BuildContext {
  AppPalette get c =>
      Theme.of(this).extension<AppPalette>() ?? kOffWhitePalette;
}
