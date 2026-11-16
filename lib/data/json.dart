typedef Json = Map<String, Object?>;

List<T> decodeList<T>(Object? json, T Function(Json item) decode) => [
  for (final item in json! as List<Object?>) decode(item! as Json),
];

double decodeDouble(Object? value) => (value! as num).toDouble();

double? decodeOptionalDouble(Object? value) => (value as num?)?.toDouble();

int decodeInt(Object? value) => (value! as num).toInt();
