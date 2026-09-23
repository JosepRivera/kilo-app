import 'package:flutter/cupertino.dart';

import '../theme/forecast_palette.dart';
import 'faded_header.dart';

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
  Widget build(BuildContext context) =>
      FadedHeaderScaffold(title: title, trailing: trailing, children: children);
}

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

class PanelHeader extends StatelessWidget {
  const PanelHeader(this.icon, this.label, {super.key, this.color});

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final p = ForecastPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color ?? p.muted),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color ?? p.muted,
            ),
          ),
        ],
      ),
    );
  }
}

class PanelDivider extends StatelessWidget {
  const PanelDivider({super.key});

  @override
  Widget build(BuildContext context) =>
      Container(height: 0.5, color: ForecastPalette.of(context).track);
}
