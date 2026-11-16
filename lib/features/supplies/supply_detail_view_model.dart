import '../../core/data_revision.dart';
import '../../core/loadable.dart';
import '../../data/models/supply_detail.dart';
import '../../data/repositories/supply_repository.dart';

class SupplyDetailViewModel extends Loadable<SupplyDetail> {
  SupplyDetailViewModel({
    required this._supplies,
    required this._revision,
    required this.supplyId,
  });

  final SupplyRepository _supplies;
  final DataRevision _revision;
  final String supplyId;
  bool _saving = false;

  bool get isSaving => _saving;

  @override
  Future<SupplyDetail> fetch() => _supplies.detail(supplyId);

  Future<String?> setCritical(bool critical) async {
    _saving = true;
    notifyListeners();
    final error = await attempt(() async {
      await _supplies.setCritical(supplyId, critical: critical);
      update(await _supplies.detail(supplyId));
      _revision.bump();
    });
    _saving = false;
    notifyListeners();
    return error;
  }
}
