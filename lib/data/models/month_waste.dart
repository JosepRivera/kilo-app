import '../json.dart';

class MonthWaste {
  const MonthWaste({required this.month, required this.soles});

  factory MonthWaste.fromJson(Json json) => MonthWaste(
    month: json['month']! as String,
    soles: decodeDouble(json['soles']),
  );

  final String month;
  final double soles;
}
