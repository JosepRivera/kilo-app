import 'package:flutter/cupertino.dart';

import '../theme/forecast_palette.dart';

/// Weather-style range bar: the dot marks what you have, the accent run is what's missing.
class RangeBar extends StatelessWidget {
  const RangeBar({super.key, required this.fraction, this.color});

  /// Position of the on-hand dot, 0..1 of what is needed.
  final double fraction;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final p = ForecastPalette.of(context);
    final f = fraction.clamp(0.0, 1.0);
    return LayoutBuilder(
      builder: (_, box) => SizedBox(
        height: 12,
        child: Stack(
          alignment: Alignment.centerLeft,
          children: [
            _bar(p.track),
            Positioned(
              left: box.maxWidth * f,
              right: 0,
              child: _bar(color ?? p.accent),
            ),
            Positioned(
              left: (box.maxWidth * f - 5).clamp(0, box.maxWidth - 10),
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: p.text,
                  shape: BoxShape.circle,
                  border: Border.all(color: p.surface, width: 2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bar(Color c) => Container(
    height: 6,
    decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(3)),
  );
}
