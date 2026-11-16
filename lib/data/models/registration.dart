import '../json.dart';
import 'restaurant.dart';

class Registration {
  const Registration({required this.token, required this.restaurant});

  factory Registration.fromJson(Json json) => Registration(
    token: json['token']! as String,
    restaurant: Restaurant.fromJson(json['restaurant']! as Json),
  );

  final String token;
  final Restaurant restaurant;
}
