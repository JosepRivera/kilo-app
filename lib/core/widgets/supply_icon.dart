import 'package:flutter/widgets.dart';

class SupplyIcon extends StatelessWidget {
  const SupplyIcon({super.key, required this.icon, this.size = 32});

  static const _generic = 'assets/supplies/generic.png';

  final String? icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    final name = icon;
    return ExcludeSemantics(
      child: Image.asset(
        name == null || name.isEmpty ? _generic : 'assets/supplies/$name.png',
        width: size,
        height: size,
        errorBuilder: (_, _, _) =>
            Image.asset(_generic, width: size, height: size),
      ),
    );
  }
}
