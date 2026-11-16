import 'package:material_ui/material_ui.dart';

import '../core/app_name.dart';
import '../core/theme/kilo_theme.dart';
import 'app_dependencies.dart';
import 'session_gate.dart';

class KiloApp extends StatelessWidget {
  const KiloApp({super.key, required this.dependencies});

  static const _locale = Locale('es', 'PE');

  final AppDependencies dependencies;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: appName,
      debugShowCheckedModeBanner: false,
      theme: KiloTheme.light,
      darkTheme: KiloTheme.dark,
      locale: _locale,
      supportedLocales: const [_locale],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: SessionGate(dependencies: dependencies),
    );
  }
}
