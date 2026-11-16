import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kilo_app/core/api_client.dart';
import 'package:kilo_app/core/api_exception.dart';

void main() {
  late List<http.Request> requests;
  late int unauthorized;

  ApiClient client(
    http.Response Function(http.Request) respond, {
    String? token = 'secret',
  }) {
    requests = [];
    unauthorized = 0;
    return ApiClient(
      httpClient: MockClient((request) async {
        requests.add(request);
        return respond(request);
      }),
      baseUrl: 'http://api.test',
      readToken: () => token,
      onUnauthorized: () => unauthorized++,
    );
  }

  test('sends the bearer token and JSON body', () async {
    final api = client((_) => http.Response('{"ok":true}', 200));
    final json = await api.post('/stock-close', {'a': 1});
    expect(json, {'ok': true});
    expect(requests.single.headers['Authorization'], 'Bearer secret');
    expect(
      requests.single.headers['Content-Type'],
      startsWith('application/json'),
    );
    expect(requests.single.body, '{"a":1}');
  });

  test('omits the header without a token and encodes queries', () async {
    final api = client((_) => http.Response('', 204), token: null);
    expect(await api.get('/catalog/resolve', query: {'term': 'limón'}), isNull);
    expect(requests.single.headers.containsKey('Authorization'), isFalse);
    expect(requests.single.url.queryParameters['term'], 'limón');
  });

  test('maps errors to the server Spanish text', () async {
    final api = client(
      (_) => http.Response.bytes(
        utf8.encode('Código de invitación inválido'),
        403,
      ),
    );
    await expectLater(
      api.post('/restaurants', {'name': 'x'}),
      throwsA(
        isA<ApiException>()
            .having((e) => e.statusCode, 'status', 403)
            .having(
              (e) => e.message,
              'message',
              'Código de invitación inválido',
            ),
      ),
    );
  });

  test('replaces non-text error bodies with a generic message', () async {
    final api = client((_) => http.Response('{"type":"validation"}', 422));
    await expectLater(
      api.get('/today'),
      throwsA(
        isA<ApiException>().having(
          (e) => e.message,
          'message',
          'No se pudo completar la operación.',
        ),
      ),
    );
  });

  test('reports 401 so the session can end', () async {
    final api = client((_) => http.Response('Token inválido', 401));
    await expectLater(api.get('/today'), throwsA(isA<ApiException>()));
    expect(unauthorized, 1);
  });

  test('turns network failures into a retryable error', () async {
    final api = ApiClient(
      httpClient: MockClient((_) => throw const SocketException('down')),
      baseUrl: 'http://api.test',
      readToken: () => null,
      onUnauthorized: () {},
    );
    await expectLater(
      api.get('/today'),
      throwsA(
        isA<ApiException>()
            .having((e) => e.statusCode, 'status', ApiException.noConnection)
            .having((e) => e.isRetryable, 'retryable', isTrue),
      ),
    );
  });

  test('only connection and provider failures are retryable', () {
    expect(const ApiException(502, '').isRetryable, isTrue);
    expect(const ApiException(503, '').isRetryable, isFalse);
    expect(const ApiException(422, '').isRetryable, isFalse);
  });
}
