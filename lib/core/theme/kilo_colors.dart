import 'package:material_ui/material_ui.dart';

class KiloColors extends ThemeExtension<KiloColors> {
  const KiloColors({
    required this.ground,
    required this.module,
    required this.track,
    required this.alert,
    required this.alertGround,
    required this.good,
    required this.accent,
  });

  static const light = KiloColors(
    ground: Color(0xFFEAF0F7),
    module: Color(0xFFFFFFFF),
    track: Color(0xFFDCE3EC),
    alert: Color(0xFFB42318),
    alertGround: Color(0xFFFDECEC),
    good: Color(0xFF1E7F46),
    accent: Color(0xFF2F6FEB),
  );

  static const dark = KiloColors(
    ground: Color(0xFF0B1422),
    module: Color(0xFF16233A),
    track: Color(0xFF24334D),
    alert: Color(0xFFFF8A80),
    alertGround: Color(0xFF3A1A1F),
    good: Color(0xFF4ADE80),
    accent: Color(0xFF5B9BFF),
  );

  final Color ground;
  final Color module;
  final Color track;
  final Color alert;
  final Color alertGround;
  final Color good;
  final Color accent;

  static KiloColors of(BuildContext context) =>
      Theme.of(context).extension<KiloColors>()!;

  @override
  KiloColors copyWith() => this;

  @override
  KiloColors lerp(KiloColors? other, double t) {
    if (other == null) return this;
    return KiloColors(
      ground: Color.lerp(ground, other.ground, t)!,
      module: Color.lerp(module, other.module, t)!,
      track: Color.lerp(track, other.track, t)!,
      alert: Color.lerp(alert, other.alert, t)!,
      alertGround: Color.lerp(alertGround, other.alertGround, t)!,
      good: Color.lerp(good, other.good, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
    );
  }
}
