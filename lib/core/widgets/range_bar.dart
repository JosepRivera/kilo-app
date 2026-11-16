import 'package:material_ui/material_ui.dart';

import '../theme/kilo_colors.dart';

class RangeBar extends StatelessWidget {
  const RangeBar({super.key, required this.fraction});

  final double fraction;

  @override
  Widget build(BuildContext context) {
    final colors = KiloColors.of(context);
    return ExcludeSemantics(
      child: SizedBox(
        height: _RangeBarPainter.dotDiameter,
        width: double.infinity,
        child: CustomPaint(
          painter: _RangeBarPainter(
            fraction: fraction.clamp(0, 1).toDouble(),
            track: colors.track,
            missing: colors.accent,
            onHand: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}

class _RangeBarPainter extends CustomPainter {
  const _RangeBarPainter({
    required this.fraction,
    required this.track,
    required this.missing,
    required this.onHand,
  });

  static const dotDiameter = 8.0;
  static const _barHeight = 6.0;

  final double fraction;
  final Color track;
  final Color missing;
  final Color onHand;

  @override
  void paint(Canvas canvas, Size size) {
    const radius = Radius.circular(_barHeight / 2);
    final top = (size.height - _barHeight) / 2;
    final split = size.width * fraction;
    canvas.drawRRect(
      RRect.fromLTRBR(0, top, size.width, top + _barHeight, radius),
      Paint()..color = track,
    );
    canvas.drawRRect(
      RRect.fromLTRBR(split, top, size.width, top + _barHeight, radius),
      Paint()..color = missing,
    );
    const dotRadius = dotDiameter / 2;
    final dotCenter = split.clamp(dotRadius, size.width - dotRadius).toDouble();
    canvas.drawCircle(
      Offset(dotCenter, size.height / 2),
      dotRadius,
      Paint()..color = onHand,
    );
  }

  @override
  bool shouldRepaint(_RangeBarPainter old) =>
      old.fraction != fraction ||
      old.track != track ||
      old.missing != missing ||
      old.onHand != onHand;
}
