import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_exception.dart';

class ApiClient {
  ApiClient({
    required http.Client httpClient,
    required this._baseUrl,
    required this._readToken,
    required this._onUnauthorized,
    this._timeout = const Duration(seconds: 30),
  }) : _http = httpClient;

  static const _unreachable =
      'No se pudo conectar con el servidor. Revisa tu conexión.';
  static const _unexpected = 'No se pudo completar la operación.';

  final http.Client _http;
  final String _baseUrl;
  final String? Function() _readToken;
  final void Function() _onUnauthorized;
  final Duration _timeout;

  Future<Object?> get(String path, {Map<String, String>? query}) =>
      _send(http.Request('GET', _uri(path, query)));

  Future<Object?> post(String path, [Object? body]) =>
      _send(_jsonRequest('POST', path, body));

  Future<Object?> patch(String path, Object body) =>
      _send(_jsonRequest('PATCH', path, body));

  Future<Object?> put(String path, Object body) =>
      _send(_jsonRequest('PUT', path, body));

  Future<Object?> postFile(
    String path, {
    required Map<String, String> fields,
    required String fileField,
    required String filePath,
  }) async {
    final request = http.MultipartRequest('POST', _uri(path))
      ..fields.addAll(fields);
    try {
      request.files.add(await http.MultipartFile.fromPath(fileField, filePath));
    } on Exception {
      throw const ApiException(ApiException.noConnection, _unexpected);
    }
    return _send(request);
  }

  Uri _uri(String path, [Map<String, String>? query]) =>
      Uri.parse('$_baseUrl$path').replace(queryParameters: query);

  http.Request _jsonRequest(String method, String path, Object? body) {
    final request = http.Request(method, _uri(path));
    if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);
    }
    return request;
  }

  Future<Object?> _send(http.BaseRequest request) async {
    final token = _readToken();
    if (token != null) request.headers['Authorization'] = 'Bearer $token';

    final http.Response response;
    try {
      final streamed = await _http.send(request).timeout(_timeout);
      response = await http.Response.fromStream(streamed).timeout(_timeout);
    } on Exception {
      throw const ApiException(ApiException.noConnection, _unreachable);
    }

    final text = utf8.decode(response.bodyBytes, allowMalformed: true);
    if (response.statusCode == 401) _onUnauthorized();
    if (response.statusCode >= 400) {
      throw ApiException(response.statusCode, _errorText(text));
    }
    if (text.isEmpty) return null;
    try {
      return jsonDecode(text);
    } on FormatException {
      throw ApiException(response.statusCode, _unexpected);
    }
  }

  String _errorText(String body) {
    final text = body.trim();
    final isPlainText = text.isNotEmpty && !text.startsWith(RegExp(r'[{<\[]'));
    return isPlainText ? text : _unexpected;
  }
}
