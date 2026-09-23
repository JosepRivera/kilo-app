import 'package:flutter/cupertino.dart';

import '../theme/forecast_palette.dart';

/// A top-level tab page: large collapsing title over the forecast ground.
class ForecastPage extends StatelessWidget {
  const ForecastPage({
    super.key,
    required this.title,
    required this.children,
    this.trailing,
  });

  final String title;
  final List<Widget> children;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final p = ForecastPalette.of(context);
    return CupertinoPageScaffold(
      backgroundColor: p.background,
      child: CustomScrollView(
        slivers: [
          CupertinoSliverNavigationBar(
            largeTitle: Text(title),
            trailing: trailing,
            backgroundColor: p.background.withValues(alpha: 0.9),
            border: null,
          ),
          SliverPadding(
            // Bottom room for the floating tab bar.
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
            sliver: SliverList.list(children: _spaced(children)),
          ),
        ],
      ),
    );
  }
}

List<Widget> _spaced(List<Widget> children) => [
  for (final (i, c) in children.indexed) ...[
    if (i > 0) const SizedBox(height: 12),
    c,
  ],
];

/// A rounded forecast module, like a weather-app card.
class Panel extends StatelessWidget {
  const Panel({
    super.key,
    required this.child,
    this.color,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final Color? color;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: color ?? ForecastPalette.of(context).surface,
      borderRadius: BorderRadius.circular(16),
    ),
    child: child,
  );
}

/// Small uppercase module caption with its glyph, as in weather modules.
class PanelHeader extends StatelessWidget {
  const PanelHeader(this.icon, this.label, {super.key});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final p = ForecastPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 16, color: p.muted),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: p.muted,
            ),
          ),
        ],
      ),
    );
  }
}

/// Hairline between rows inside a panel.
class PanelDivider extends StatelessWidget {
  const PanelDivider({super.key});

  @override
  Widget build(BuildContext context) =>
      Container(height: 0.5, color: ForecastPalette.of(context).track);
}
