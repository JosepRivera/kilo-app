import '../core/data_revision.dart';
import '../data/recorder/voice_recorder.dart';
import '../data/repositories/insight_repository.dart';
import '../data/repositories/record_repository.dart';
import '../data/repositories/restaurant_repository.dart';
import '../data/repositories/supply_repository.dart';
import '../data/repositories/voice_repository.dart';
import '../data/session.dart';
import '../data/stores/bought_store.dart';
import '../data/stores/close_draft_store.dart';

class AppDependencies {
  AppDependencies({
    required this.session,
    required this.restaurants,
    required this.supplies,
    required this.records,
    required this.insights,
    required this.voice,
    required this.boughtStore,
    required this.closeDrafts,
    required this.createRecorder,
    this.clock = DateTime.now,
  });

  final Session session;
  final RestaurantRepository restaurants;
  final SupplyRepository supplies;
  final RecordRepository records;
  final InsightRepository insights;
  final VoiceRepository voice;
  final BoughtStore boughtStore;
  final CloseDraftStore closeDrafts;
  final VoiceRecorder Function() createRecorder;
  final DateTime Function() clock;
  final DataRevision revision = DataRevision();
}
