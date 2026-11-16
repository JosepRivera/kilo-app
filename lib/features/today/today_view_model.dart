import '../../core/day.dart';
import '../../core/loadable.dart';
import '../../data/models/purchase_suggestion.dart';
import '../../data/models/today_overview.dart';
import '../../data/repositories/insight_repository.dart';
import '../../data/repositories/supply_repository.dart';
import '../../data/stores/bought_store.dart';
import 'bought_merge.dart';

class TodayViewModel extends Loadable<TodayOverview> {
  TodayViewModel({
    required this._insights,
    required this._supplies,
    required this._boughtStore,
    super.refreshOn,
  });

  static const _merge = BoughtMerge();

  final InsightRepository _insights;
  final SupplyRepository _supplies;
  final BoughtStore _boughtStore;
  Set<String> _checked = const {};
  bool _needsFirstCount = false;

  bool get needsFirstCount => _needsFirstCount;

  @override
  Future<TodayOverview> fetch() async {
    final overview = await _insights.today();
    _checked = await _boughtStore.read(formatDay(overview.day));
    _needsFirstCount = overview.isEmpty && (await _supplies.all()).isEmpty;
    return overview;
  }

  bool isBought(PurchaseSuggestion item) => _merge.isBought(item, _checked);

  Future<void> toggleBought(PurchaseSuggestion item) async {
    final overview = value;
    if (overview == null || item.bought) return;
    final supplyId = item.supply.id;
    _checked = _checked.contains(supplyId)
        ? _checked.difference({supplyId})
        : {..._checked, supplyId};
    notifyListeners();
    await _boughtStore.write(formatDay(overview.day), _checked);
  }
}
