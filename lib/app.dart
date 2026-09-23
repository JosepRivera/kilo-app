import 'dart:ui' show ImageFilter;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show DefaultMaterialLocalizations;
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

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

/// Tabs are places (Hoy, Insumos, Ahorro); dictating is an action, so the mic floats beside the bar.
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
    return CupertinoPageScaffold(
      backgroundColor: p.background,
      child: Stack(
        children: [
          // Each tab keeps its own navigation stack, so the floating bar stays over pushed pages.
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
                        onPressed: () => _openDictation(context),
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
    );
  }
}

/// System-style translucent material for floating bars (Flutter has no native Liquid Glass).
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

enum _VoiceAction { stockClose, purchase }

// Night (after 5pm, before the ~5-6am processing cut) is the stock close; otherwise it is a purchase.
_VoiceAction _actionForTime(DateTime t) => t.hour >= 17 || t.hour < 6
    ? _VoiceAction.stockClose
    : _VoiceAction.purchase;

void _openDictation(BuildContext context) => showCupertinoModalPopup<void>(
  context: context,
  builder: (_) => _DictationSheet(initial: _actionForTime(DateTime.now())),
);

// ponytail: listening state only; recording + transcription lands with Fases 2 and 5.
class _DictationSheet extends StatefulWidget {
  const _DictationSheet({required this.initial});

  final _VoiceAction initial;

  @override
  State<_DictationSheet> createState() => _DictationSheetState();
}

class _DictationSheetState extends State<_DictationSheet> {
  late var _action = widget.initial;

  @override
  Widget build(BuildContext context) {
    final p = ForecastPalette.of(context);
    final stockClose = _action == _VoiceAction.stockClose;
    return Container(
      height: 380,
      width: double.infinity,
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Column(
            children: [
              CupertinoSlidingSegmentedControl<_VoiceAction>(
                groupValue: _action,
                onValueChanged: (a) => setState(() => _action = a!),
                children: const {
                  _VoiceAction.stockClose: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('Cierre de hoy'),
                  ),
                  _VoiceAction.purchase: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('Compra'),
                  ),
                },
              ),
              const Spacer(),
              Icon(CupertinoIcons.mic_circle_fill, size: 88, color: p.accent),
              const SizedBox(height: 12),
              Text(
                'Te escucho',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: p.text,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                stockClose
                    ? '¿Cuánto queda de cada insumo?'
                    : 'Qué compraste, cuánto y a cuánto',
                style: TextStyle(fontSize: 17, color: p.muted),
              ),
              const Spacer(),
              CupertinoButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Listo',
                  style: TextStyle(
                    color: p.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
