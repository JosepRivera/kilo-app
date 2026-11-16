import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:material_ui/material_ui.dart';
import 'package:record/record.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/api_base_url.dart';
import 'app/app_dependencies.dart';
import 'app/kilo_app.dart';
import 'core/api_client.dart';
import 'data/recorder/device_voice_recorder.dart';
import 'data/repositories/insight_repository.dart';
import 'data/repositories/record_repository.dart';
import 'data/repositories/restaurant_repository.dart';
import 'data/repositories/supply_repository.dart';
import 'data/repositories/voice_repository.dart';
import 'data/session.dart';
import 'data/stores/prefs_bought_store.dart';
import 'data/stores/prefs_close_draft_store.dart';
import 'data/stores/secure_token_store.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final session = Session(const SecureTokenStore(FlutterSecureStorage()));
  final api = ApiClient(
    httpClient: http.Client(),
    baseUrl: apiBaseUrl(),
    readToken: () => session.token,
    onUnauthorized: () => unawaited(session.signOut()),
  );
  final prefs = SharedPreferencesAsync();
  unawaited(session.restore());
  runApp(
    KiloApp(
      dependencies: AppDependencies(
        session: session,
        restaurants: RestaurantRepository(api),
        supplies: SupplyRepository(api),
        records: RecordRepository(api),
        insights: InsightRepository(api),
        voice: VoiceRepository(api),
        boughtStore: PrefsBoughtStore(prefs),
        closeDrafts: PrefsCloseDraftStore(prefs),
        createRecorder: () => DeviceVoiceRecorder(AudioRecorder()),
      ),
    ),
  );
}
