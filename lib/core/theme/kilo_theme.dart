import 'package:material_ui/material_ui.dart';

import 'kilo_colors.dart';

abstract final class KiloTheme {
  static const minTapTarget = 48.0;

  static const _tabular = TextStyle(
    letterSpacing: 0,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const _textTheme = TextTheme(
    displayLarge: _tabular,
    displayMedium: _tabular,
    displaySmall: _tabular,
    headlineLarge: _tabular,
    headlineMedium: _tabular,
    headlineSmall: _tabular,
    titleLarge: _tabular,
    titleMedium: _tabular,
    titleSmall: _tabular,
    bodyLarge: _tabular,
    bodyMedium: _tabular,
    bodySmall: _tabular,
    labelLarge: _tabular,
    labelMedium: _tabular,
    labelSmall: _tabular,
  );

  static final light = _build(Brightness.light, KiloColors.light);

  static final dark = _build(Brightness.dark, KiloColors.dark);

  static ThemeData _build(Brightness brightness, KiloColors colors) {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: colors.accent,
          brightness: brightness,
        ).copyWith(
          primary: colors.accent,
          surface: colors.ground,
          surfaceContainerLow: colors.module,
          surfaceContainer: colors.module,
          surfaceContainerHigh: colors.module,
          error: colors.alert,
        );
    return ThemeData(
      colorScheme: scheme,
      scaffoldBackgroundColor: colors.ground,
      textTheme: _textTheme,
      extensions: [colors],
      materialTapTargetSize: MaterialTapTargetSize.padded,
      appBarTheme: AppBarTheme(
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
          color: scheme.onSurface,
        ),
        backgroundColor: colors.ground,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colors.module,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.ground,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
      ),
      dividerTheme: DividerThemeData(color: colors.track, thickness: 1),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        linearTrackColor: colors.track,
      ),
    );
  }
}
