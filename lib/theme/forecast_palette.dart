import 'package:flutter/cupertino.dart';

class ForecastPalette {
  const ForecastPalette._({
    required this.background,
    required this.surface,
    required this.text,
    required this.muted,
    required this.track,
    required this.accent,
    required this.onAccent,
    required this.alertBackground,
    required this.alert,
    required this.glass,
    required this.good,
  });

  final Color background,
      surface,
      text,
      muted,
      track,
      accent,
      onAccent,
      alertBackground,
      alert,
      glass,
      good;

  static const light = ForecastPalette._(
    background: Color(0xFFEAF0F7),
    surface: Color(0xFFFFFFFF),
    text: Color(0xFF0E1726),
    muted: Color(0xFF5B6778),
    track: Color(0xFFDCE3EC),
    accent: Color(0xFF2F6FEB),
    onAccent: Color(0xFFFFFFFF),
    alertBackground: Color(0xFFFDECEC),
    alert: Color(0xFFB42318),
    glass: Color(0xB8FFFFFF),
    good: Color(0xFF1E7F46),
  );

  static const dark = ForecastPalette._(
    background: Color(0xFF0B1422),
    surface: Color(0xFF16233A),
    text: Color(0xFFEEF3FA),
    muted: Color(0xFF8FA0B8),
    track: Color(0xFF24334D),
    accent: Color(0xFF5B9BFF),
    onAccent: Color(0xFF0B1422),
    alertBackground: Color(0xFF3A1A1F),
    alert: Color(0xFFFF8A80),
    glass: Color(0xB8233249),
    good: Color(0xFF4ADE80),
  );

  static ForecastPalette of(BuildContext c) =>
      CupertinoTheme.brightnessOf(c) == Brightness.dark ? dark : light;
}
