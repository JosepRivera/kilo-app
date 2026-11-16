class ApiException implements Exception {
  const ApiException(this.statusCode, this.message);

  static const noConnection = 0;

  final int statusCode;
  final String message;

  bool get isRetryable => statusCode == noConnection || statusCode == 502;

  @override
  String toString() => message;
}
