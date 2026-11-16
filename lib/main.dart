import 'package:material_ui/material_ui.dart';

import 'core/app_name.dart';
import 'core/theme/kilo_theme.dart';

void main() => runApp(
  MaterialApp(
    title: appName,
    theme: KiloTheme.light,
    darkTheme: KiloTheme.dark,
    home: const Scaffold(),
  ),
);
