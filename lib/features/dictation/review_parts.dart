import 'package:flutter/cupertino.dart';

import '../../theme/forecast_palette.dart';
import '../../ui/panel.dart';

/// Full-screen review after dictating: Cancel / title / Save, content in forecast panels.
class ReviewScaffold extends StatelessWidget {
  const ReviewScaffold({
    super.key,
    required this.title,
    required this.children,
    required this.canSave,
    required this.onSave,
  });

  final String title;
  final List<Widget> children;
  final bool canSave;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final p = ForecastPalette.of(context);
    return CupertinoPageScaffold(
      backgroundColor: p.background,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: p.background.withValues(alpha: 0.9),
        border: null,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        middle: Text(title),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: canSave ? onSave : null,
          child: const Text(
            'Guardar',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            for (final (i, c) in children.indexed) ...[
              if (i > 0) const SizedBox(height: 12),
              c,
            ],
          ],
        ),
      ),
    );
  }
}

/// What Kilo heard, so the person can see why each number is there.
class TranscriptPanel extends StatelessWidget {
  const TranscriptPanel(this.transcript, {super.key});

  final String transcript;

  @override
  Widget build(BuildContext context) {
    final p = ForecastPalette.of(context);
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PanelHeader(CupertinoIcons.waveform, 'ESCUCHÉ'),
          Text(
            '“$transcript”',
            style: TextStyle(
              fontSize: 15,
              fontStyle: FontStyle.italic,
              color: p.muted,
            ),
          ),
        ],
      ),
    );
  }
}

/// A "revisar" check: Kilo explains why it asks and offers two answers; nothing is applied on its own.
class FlagPanel extends StatelessWidget {
  const FlagPanel({
    super.key,
    required this.icon,
    required this.message,
    required this.primary,
    required this.secondary,
    required this.onPrimary,
    required this.onSecondary,
    this.resolved,
  });

  final Widget icon;
  final String message, primary, secondary;
  final VoidCallback onPrimary, onSecondary;

  /// Shown instead of the buttons once answered.
  final String? resolved;

  @override
  Widget build(BuildContext context) {
    final p = ForecastPalette.of(context);
    final done = resolved != null;
    return Panel(
      color: done ? p.surface : p.alertBackground,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              icon,
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      done ? 'Revisado' : 'Revisar',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: done ? p.good : p.alert,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      message,
                      style: TextStyle(fontSize: 17, color: p.text),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (done)
            Row(
              children: [
                Icon(CupertinoIcons.checkmark_alt, size: 18, color: p.good),
                const SizedBox(width: 6),
                Text(resolved!, style: TextStyle(fontSize: 15, color: p.good)),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: CupertinoButton(
                    color: p.accent,
                    borderRadius: BorderRadius.circular(12),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    onPressed: onPrimary,
                    child: Text(
                      primary,
                      style: TextStyle(
                        color: p.onAccent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: CupertinoButton(
                    color: p.surface,
                    borderRadius: BorderRadius.circular(12),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    onPressed: onSecondary,
                    child: Text(
                      secondary,
                      style: TextStyle(
                        color: p.accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// Numeric entry sized for a quantity column.
class QuantityField extends StatelessWidget {
  const QuantityField({
    super.key,
    required this.controller,
    required this.unit,
    this.width = 84,
    this.focusNode,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final String unit;
  final double width;

  @override
  Widget build(BuildContext context) {
    final p = ForecastPalette.of(context);
    return SizedBox(
      width: width,
      child: CupertinoTextField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textAlign: TextAlign.right,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        suffix: Padding(
          padding: const EdgeInsets.only(right: 10),
          child: Text(unit, style: TextStyle(fontSize: 15, color: p.muted)),
        ),
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: p.text,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
        decoration: BoxDecoration(
          color: p.background,
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}
