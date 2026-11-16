import '../../core/loadable.dart';
import '../../data/models/savings.dart';
import '../../data/repositories/insight_repository.dart';

class SavingsViewModel extends Loadable<Savings> {
  SavingsViewModel({required this._insights, super.refreshOn});

  final InsightRepository _insights;

  @override
  Future<Savings> fetch() => _insights.savings();
}
