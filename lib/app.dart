import 'dart:ui' show ImageFilter;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show DefaultMaterialLocalizations;
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'features/dictation/dictation_sheet.dart';
import 'features/savings/savings_screen.dart';
import 'features/supplies/supplies_screen.dart';
import 'features/today/today_screen.dart';
import 'theme/forecast_palette.dart';

class KiloApp extends StatelessWidget {
  const KiloApp({super.key});

  @override
  Widget build(BuildContext context) => CupertinoApp(
    title: 'Kilo',
    debugShowCheckedModeBanner: false,
    locale: const Locale('es', 'PE'),
    supportedLocales: const [Locale('es', 'PE')],
    localizationsDelegates: const [
      ...GlobalMaterialLocalizations.delegates,
      DefaultMaterialLocalizations.delegate,
    ],
    home: const _Shell(),
  );
}

const _tabs = [
  (CupertinoIcons.sun_max_fill, 'Hoy'),
  (CupertinoIcons.square_list_fill, 'Insumos'),
  (CupertinoIcons.chart_bar_alt_fill, 'Ahorro'),
];

class _Shell extends StatefulWidget {
  const _Shell();

  @override
  State<_Shell> createState() => _ShellState();
}

class _ShellState extends State<_Shell> {
  var _tab = 0;

  @override
  Widget build(BuildContext context) {
    final p = ForecastPalette.of(context);
    final dark = CupertinoTheme.brightnessOf(context) == Brightness.dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: const Color(0x00000000),
        statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
        statusBarBrightness: dark ? Brightness.dark : Brightness.light,
        systemStatusBarContrastEnforced: false,
        systemNavigationBarColor: const Color(0x00000000),
        systemNavigationBarIconBrightness: dark
            ? Brightness.light
            : Brightness.dark,
        systemNavigationBarContrastEnforced: false,
      ),
      child: CupertinoPageScaffold(
        backgroundColor: p.background,
        child: Stack(
          children: [
            IndexedStack(
              index: _tab,
              children: [
                CupertinoTabView(builder: (_) => const TodayScreen()),
                CupertinoTabView(builder: (_) => const SuppliesScreen()),
                CupertinoTabView(builder: (_) => const SavingsScreen()),
              ],
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 0,
              child: SafeArea(
                top: false,
                minimum: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: _Glass(
                        child: Row(
                          children: [
                            for (final (n, t) in _tabs.indexed)
                              Expanded(
                                child: _TabItem(
                                  icon: t.$1,
                                  name: t.$2,
                                  active: n == _tab,
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    setState(() => _tab = n);
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    _Glass(
                      circle: true,
                      child: Semantics(
                        button: true,
                        label: 'Dictar',
                        child: CupertinoButton(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(64, 64),
                          onPressed: () => openDictation(context),
                          child: Icon(
                            CupertinoIcons.mic_fill,
                            size: 26,
                            color: p.accent,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Glass extends StatelessWidget {
  const _Glass({required this.child, this.circle = false});

  final Widget child;
  final bool circle;

  @override
  Widget build(BuildContext context) {
    final p = ForecastPalette.of(context);
    final shape = BorderRadius.circular(32);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: shape,
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: shape,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            height: 64,
            width: circle ? 64 : null,
            decoration: BoxDecoration(
              color: p.glass,
              borderRadius: shape,
              border: Border.all(
                color: p.text.withValues(alpha: 0.08),
                width: 0.5,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.icon,
    required this.name,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String name;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = ForecastPalette.of(context);
    final color = active ? p.accent : p.muted;
    return Semantics(
      button: true,
      selected: active,
      label: name,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ExcludeSemantics(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutExpo,
            margin: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: active ? p.accent.withValues(alpha: 0.12) : null,
              borderRadius: BorderRadius.circular(27),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 22, color: color),
                const SizedBox(height: 2),
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
