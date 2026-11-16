import '../../core/data_revision.dart';
import '../../core/day.dart';
import '../../core/loadable.dart';
import '../../data/models/catalog_candidate.dart';
import '../../data/models/new_supply.dart';
import '../../data/models/purchase_line.dart';
import '../../data/models/resolution_kind.dart';
import '../../data/models/supply.dart';
import '../../data/models/supply_category.dart';
import '../../data/models/voice_draft.dart';
import '../../data/models/voice_item.dart';
import '../../data/repositories/record_repository.dart';
import '../../data/repositories/restaurant_repository.dart';
import '../../data/repositories/supply_repository.dart';
import '../catalog/candidate_resolver.dart';
import 'line_problem.dart';
import 'price_flag.dart';
import 'purchase_line_draft.dart';
import 'purchase_line_rules.dart';

class PurchaseReviewViewModel extends Loadable<List<Supply>> {
  PurchaseReviewViewModel({
    required SupplyRepository supplies,
    required this._restaurants,
    required this._records,
    required this._revision,
    this._voice,
    this._clock = DateTime.now,
  }) : _supplies = supplies,
       _resolver = CandidateResolver(supplies);

  static const _rules = PurchaseLineRules();

  final SupplyRepository _supplies;
  final RestaurantRepository _restaurants;
  final RecordRepository _records;
  final DataRevision _revision;
  final CandidateResolver _resolver;
  final VoiceDraft? _voice;
  final DateTime Function() _clock;

  List<PurchaseLineDraft> _lines = const [];
  List<SupplyCategory> _categories = const [];
  int _nextId = 0;
  bool _edited = false;
  bool _busy = false;

  List<PurchaseLineDraft> get lines => _lines;
  List<SupplyCategory> get categories => _categories;
  String? get transcript => _voice?.transcript;
  bool get isBusy => _busy;
  bool get hasUnsavedEdits => _edited || _lines.isNotEmpty;
  DateTime get today => businessDay(_clock());

  double get total => _lines.fold(
    0,
    (sum, line) => sum + (line.supply == null ? 0 : line.cost ?? 0),
  );

  bool get canSave =>
      !_busy && _lines.isNotEmpty && _lines.every(_rules.isValid);

  PriceFlag? priceFlagOf(PurchaseLineDraft line) =>
      line.priceConfirmed ? null : _rules.priceFlag(line);

  LineProblem? problemOf(PurchaseLineDraft line) => _rules.problem(line);

  PurchaseLineDraft? lineById(int id) {
    for (final line in _lines) {
      if (line.id == id) return line;
    }
    return null;
  }

  @override
  Future<List<Supply>> fetch() async {
    final (supplies, categories) = await (
      _supplies.all(),
      _restaurants.categories(),
    ).wait;
    _categories = categories;
    _lines = [
      for (final item in _voice?.items ?? const <VoiceItem>[])
        await _lineFrom(item, supplies),
    ];
    return supplies;
  }

  Future<PurchaseLineDraft> _lineFrom(
    VoiceItem item,
    List<Supply> known,
  ) async {
    final line = PurchaseLineDraft(
      id: _nextId++,
      spoken: item.spoken,
      candidates: item.resolution.candidates,
      quantity: item.quantity,
      cost: item.cost,
      phrase: item.quantity == null ? item.phrase : null,
    );
    if (item.resolution.kind != ResolutionKind.exact) return line;
    final supply = await _resolver.resolve(
      item.resolution.candidates.single,
      known,
    );
    return line.resolvedAs(supply, _rules.defaultExpiry(supply, today));
  }

  void setQuantity(int id, double? quantity) =>
      _update(id, (line) => line.withQuantity(quantity));

  void setCost(int id, double? cost) =>
      _update(id, (line) => line.withCost(cost));

  void setExpiry(int id, DateTime expiresOn) =>
      _update(id, (line) => line.withExpiry(expiresOn));

  void answerMeasure(int id, double quantity) {
    if (quantity > 0) _update(id, (line) => line.withMeasure(quantity));
  }

  void confirmPrice(int id) => _update(id, (line) => line.withPriceConfirmed());

  void remove(int id) {
    _lines = [..._lines.where((line) => line.id != id)];
    _edited = true;
    notifyListeners();
  }

  Future<String?> pickCandidate(int id, CatalogCandidate candidate) =>
      _run(() async {
        final supply = await _resolver.resolve(candidate, value ?? const []);
        _resolve(id, supply);
      });

  Future<String?> createSupply(int id, NewSupply supply) => _run(() async {
    _resolve(id, await _resolver.create(supply));
  });

  Future<String?> addCandidate(CatalogCandidate candidate) => _run(() async {
    _append(await _resolver.resolve(candidate, value ?? const []));
  });

  Future<String?> addNew(NewSupply supply) => _run(() async {
    _append(await _resolver.create(supply));
  });

  Future<String?> save() => _run(() async {
    for (final line in _lines) {
      final phrase = line.phraseToRemember;
      if (phrase == null) continue;
      await _supplies.rememberPhrase(
        line.supply!.id,
        phrase: phrase,
        amount: line.quantity!,
      );
    }
    await _records.savePurchase([
      for (final line in _lines)
        PurchaseLine(
          supplyId: line.supply!.id,
          quantity: line.quantity!,
          cost: line.cost!,
          expiresOn:
              line.expiresOn ?? _rules.defaultExpiry(line.supply!, today),
        ),
    ]);
    _lines = const [];
    _edited = false;
    _revision.bump();
  });

  void _resolve(int id, Supply supply) => _update(
    id,
    (line) => line.resolvedAs(supply, _rules.defaultExpiry(supply, today)),
  );

  void _append(Supply supply) {
    _lines = [
      ..._lines,
      PurchaseLineDraft(
        id: _nextId++,
        spoken: supply.name,
        supply: supply,
        expiresOn: _rules.defaultExpiry(supply, today),
      ),
    ];
    _edited = true;
  }

  void _update(int id, PurchaseLineDraft Function(PurchaseLineDraft) change) {
    _lines = [for (final line in _lines) line.id == id ? change(line) : line];
    _edited = true;
    notifyListeners();
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
