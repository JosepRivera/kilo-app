import 'package:kilo_app/data/models/close_draft.dart';
import 'package:kilo_app/data/stores/bought_store.dart';
import 'package:kilo_app/data/stores/close_draft_store.dart';
import 'package:kilo_app/data/stores/token_store.dart';

class MemoryTokenStore implements TokenStore {
  String? token;

  @override
  Future<String?> read() async => token;

  @override
  Future<void> write(String token) async => this.token = token;

  @override
  Future<void> clear() async => token = null;
}

class MemoryCloseDraftStore implements CloseDraftStore {
  CloseDraft? draft;

  @override
  Future<CloseDraft?> read() async => draft;

  @override
  Future<void> write(CloseDraft draft) async => this.draft = draft;

  @override
  Future<void> clear() async => draft = null;
}

class MemoryBoughtStore implements BoughtStore {
  final Map<String, Set<String>> days = {};

  @override
  Future<Set<String>> read(String day) async => {...?days[day]};

  @override
  Future<void> write(String day, Set<String> supplyIds) async =>
      days[day] = {...supplyIds};
}
