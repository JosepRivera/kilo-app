import '../json.dart';

class Restaurant {
  const Restaurant({
    required this.id,
    required this.name,
    required this.closedWeekdays,
  });

  factory Restaurant.fromJson(Json json) => Restaurant(
    id: json['id']! as String,
    name: json['name']! as String,
    closedWeekdays: [
      for (final day in json['closedWeekdays']! as List<Object?>)
        decodeInt(day),
    ],
  );

  final String id;
  final String name;
  final List<int> closedWeekdays;
}
