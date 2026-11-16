import '../json.dart';
import 'month_waste.dart';
import 'wasted_supply.dart';

class Savings {
  const Savings({
    required this.months,
    required this.current,
    required this.previous,
    required this.topWasted,
  });

  factory Savings.fromJson(Json json) => Savings(
    months: decodeList(json['months'], MonthWaste.fromJson),
    current: decodeDouble(json['current']),
    previous: decodeDouble(json['previous']),
    topWasted: decodeList(json['topWasted'], WastedSupply.fromJson),
  );

  final List<MonthWaste> months;
  final double current;
  final double previous;
  final List<WastedSupply> topWasted;
}
