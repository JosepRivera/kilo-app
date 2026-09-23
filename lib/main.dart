import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'data/store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_PE');
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  final store = await KiloStore.load();
  runApp(KiloApp(store: store));
}
