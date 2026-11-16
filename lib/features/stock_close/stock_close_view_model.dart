import 'dart:async';

import '../../core/data_revision.dart';
import '../../core/day.dart';
import '../../core/loadable.dart';
import '../../data/models/catalog_candidate.dart';
import '../../data/models/close_draft.dart';
import '../../data/models/new_supply.dart';
import '../../data/models/resolution_kind.dart';
import '../../data/models/supply.dart';
import '../../data/models/supply_category.dart';
import '../../data/models/voice_draft.dart';
import '../../data/repositories/record_repository.dart';
import '../../data/repositories/restaurant_repository.dart';
import '../../data/repositories/supply_repository.dart';
import '../../data/stores/close_draft_store.dart';
import '../catalog/candidate_resolver.dart';
import '../catalog/pending_item.dart';
import 'close_entry.dart';
import 'close_flag.dart';
import 'close_review_rules.dart';

class StockCloseViewModel extends Loadable<List<Supply>> {
  StockCloseViewModel({
    required SupplyRepository supplies,
    required this._restaurants,
    required this._records,
    required this._drafts,
    required this._revision,
    this._voice,
    this._clock = DateTime.now,
  }) : _resolver = CandidateResolver(supplies),
       _supplies = supplies;

  static const _rules = CloseReviewRules();

  final SupplyRepository _supplies;
  final RestaurantRepository _restaurants;
  final RecordRepository _records;
  final CloseDraftStore _drafts;
  final DataRevision _revision;
  final CandidateResolver _resolver;
  final VoiceDraft? _voice;
  final DateTime Function() _clock;

  List<CloseEntry> _entries = const [];
  List<PendingItem> _pending = const [];
  List<SupplyCategory> _categories = const [];
  bool _resumed = false;
  String? _transcript;
  bool _edited = false;
  bool _busy = false;

  List<CloseEntry> get entries => _entries;
  List<PendingItem> get pending => _pending;
  List<SupplyCategory> get categories => _categories;
  String? get transcript => _transcript;
  bool get resumedFromDraft => _resumed;
  bool get isBusy => _busy;
  bool get hasUnsavedEdits => _edited || _resumed;

  bool get canSave =>
      !_busy &&
      _entries.isNotEmpty &&
      _pending.isEmpty &&
      _entries.every(
        (entry) =>
            entry.remaining != null &&
            entry.remaining! >= 0 &&
            entry.suggested == null &&
            (flagOf(entry) == null || entry.flagConfirmed),
      );

  String get _today => formatDay(businessDay(_clock()));

  CloseFlag? flagOf(CloseEntry entry) {
    final remaining = entry.remaining;
    return remaining == null ? null : _rules.flag(entry.supply, remaining);
  }

  bool needsReview(CloseEntry entry) =>
      flagOf(entry) != null && !entry.flagConfirmed;

  @override
  Future<List<Supply>> fetch() async {
    final (supplies, categories, draft) = await (
      _supplies.all(),
      _restaurants.categories(),
      _drafts.read(),
    ).wait;
    _categories = categories;
    final resumable = _voice == null && draft?.day == _today;
    await _build(supplies, resumable ? draft : null);
    return supplies;
  }

  Future<void> _build(List<Supply> known, CloseDraft? draft) async {
    final heard = <String, double?>{};
    final suggested = <String, double>{};
    final pending = <PendingItem>[];
    final mentioned = <Supply>[];
    for (final (index, item) in (_voice?.items ?? const []).indexed) {
      if (item.resolution.kind != ResolutionKind.exact) {
        pending.add(
          PendingItem(
            id: index,
            spoken: item.spoken,
            candidates: item.resolution.candidates,
            quantity: item.quantity,
          ),
        );
        continue;
      }
      final supply = await _resolver.resolve(
        item.resolution.candidates.single,
        known,
      );
      mentioned.add(supply);
      heard[supply.id] = item.quantity;
      final suggestion = item.suggestedQuantity;
      if (suggestion != null) suggested[supply.id] = suggestion;
    }
    final rows = <String, Supply>{
      for (final supply in known)
        if (supply.dueForClose) supply.id: supply,
      for (final supply in mentioned) supply.id: supply,
    };
    final saved = draft?.remaining ?? const <String, double>{};
    for (final id in saved.keys) {
      for (final supply in known) {
        if (supply.id == id) rows.putIfAbsent(id, () => supply);
      }
    }
    _resumed = draft != null;
    _transcript = draft != null ? draft.transcript : _voice?.transcript;
    _pending = draft != null ? const [] : pending;
    _entries = [
      for (final supply in rows.values)
        CloseEntry(
          supply: supply,
          remaining: draft != null
              ? saved[supply.id]
              : heard.containsKey(supply.id)
              ? heard[supply.id]
              : supply.expectedRemaining,
          suggested: draft != null ? null : suggested[supply.id],
        ),
    ];
  }

  void setRemaining(String supplyId, double? remaining) {
    _replace(supplyId, (entry) => entry.edited(remaining));
    _persist();
  }

  void confirmFlag(String supplyId) =>
      _replace(supplyId, (entry) => entry.withFlagConfirmed());

  void acceptSuggestion(String supplyId) {
    _replace(supplyId, (entry) => entry.edited(entry.suggested));
    _persist();
  }

  void keepHeard(String supplyId) =>
      _replace(supplyId, (entry) => entry.withoutSuggestion());

  Future<String?> pickCandidate(PendingItem item, CatalogCandidate candidate) =>
      _run(() async {
        final supply = await _resolver.resolve(candidate, value ?? const []);
        _addEntry(supply, item.quantity ?? supply.expectedRemaining);
        _pending = [..._pending.where((p) => p.id != item.id)];
      });

  Future<String?> createSupply(PendingItem item, NewSupply supply) =>
      _run(() async {
        final created = await _resolver.create(supply);
        _addEntry(created, item.quantity);
        _pending = [..._pending.where((p) => p.id != item.id)];
      });

  Future<String?> addCandidate(CatalogCandidate candidate) => _run(() async {
    final supply = await _resolver.resolve(candidate, value ?? const []);
    _addEntry(supply, null);
  });

  Future<String?> addNew(NewSupply supply) => _run(() async {
    _addEntry(await _resolver.create(supply), null);
  });

  void removePending(PendingItem item) {
    _pending = [..._pending.where((p) => p.id != item.id)];
    _edited = true;
    notifyListeners();
  }

  Future<void> restart() async {
    await _drafts.clear();
    _resumed = false;
    _edited = false;
    await load();
  }

  Future<void> discard() => _drafts.clear();

  Future<String?> save() => _run(() async {
    await _records.closeStock({
      for (final entry in _entries) entry.supply.id: entry.remaining!,
    });
    await _drafts.clear();
    _edited = false;
    _resumed = false;
    _revision.bump();
  });

  Future<String?> markNoConsumption() => _run(() async {
    await _records.markNoConsumption();
    await _drafts.clear();
    _edited = false;
    _resumed = false;
    _revision.bump();
  });

  void _addEntry(Supply supply, double? remaining) {
    if (_entries.any((entry) => entry.supply.id == supply.id)) return;
    _entries = [..._entries, CloseEntry(supply: supply, remaining: remaining)];
    _persist();
  }

  void _replace(String supplyId, CloseEntry Function(CloseEntry) change) {
    _entries = [
      for (final entry in _entries)
        entry.supply.id == supplyId ? change(entry) : entry,
    ];
    _edited = true;
    notifyListeners();
  }

  void _persist() {
    _edited = true;
    notifyListeners();
    unawaited(
      _drafts.write(
        CloseDraft(
          day: _today,
          transcript: transcript,
          remaining: {
            for (final entry in _entries)
              if (entry.remaining != null) entry.supply.id: entry.remaining!,
          },
        ),
      ),
    );
  }

  Future<String?> _run(Future<void> Function() action) async {
    _busy = true;
    notifyListeners();
    final error = await attempt(action);
    _busy = false;
    notifyListeners();
    return error;
  }
}
