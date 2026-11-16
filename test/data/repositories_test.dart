import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kilo_app/core/api_client.dart';
import 'package:kilo_app/core/api_exception.dart';
import 'package:kilo_app/data/models/new_supply.dart';
import 'package:kilo_app/data/models/purchase_line.dart';
import 'package:kilo_app/data/models/voice_kind.dart';
import 'package:kilo_app/data/repositories/insight_repository.dart';
import 'package:kilo_app/data/repositories/record_repository.dart';
import 'package:kilo_app/data/repositories/restaurant_repository.dart';
import 'package:kilo_app/data/repositories/supply_repository.dart';
import 'package:kilo_app/data/repositories/voice_repository.dart';

import 'models_test.dart' show recommendation, supplyView;

class Recorded {
  Recorded(this.method, this.path, this.query, this.body, this.request);

  final String method;
  final String path;
  final Map<String, String> query;
  final Object? body;
  final http.BaseRequest request;
}

void main() {
  late List<Recorded> calls;

  ApiClient api(String responseBody, {int status = 200}) {
    calls = [];
    return ApiClient(
      httpClient: MockClient((request) async {
        final text = request.body;
        calls.add(
          Recorded(
            request.method,
            request.url.path,
            request.url.queryParameters,
            text.isEmpty || !text.startsWith('{') ? text : jsonDecode(text),
            request,
          ),
        );
        return http.Response.bytes(utf8.encode(responseBody), status);
      }),
      baseUrl: 'http://api.test',
      readToken: () => 'token',
      onUnauthorized: () {},
    );
  }

  group('RestaurantRepository', () {
    const restaurant = '{"id":"r","name":"Doña Rosa","closedWeekdays":[7]}';

    test('registers with name and optional invite code', () async {
      final repo = RestaurantRepository(
        api('{"token":"t","restaurant":$restaurant}', status: 201),
      );
      final registration = await repo.register(name: 'Doña Rosa');
      expect(registration.token, 't');
      expect(calls.single.method, 'POST');
      expect(calls.single.path, '/restaurants');
      expect(calls.single.body, {'name': 'Doña Rosa'});

      await repo.register(name: 'Doña Rosa', inviteCode: 'abc');
      expect(calls.last.body, {'name': 'Doña Rosa', 'inviteCode': 'abc'});
    });

    test('reads and patches the restaurant', () async {
      final repo = RestaurantRepository(api(restaurant));
      expect((await repo.current()).name, 'Doña Rosa');
      await repo.update(closedWeekdays: [6, 7]);
      expect(calls.last.method, 'PATCH');
      expect(calls.last.path, '/restaurant');
      expect(calls.last.body, {
        'closedWeekdays': [6, 7],
      });
    });

    test('lists and patches categories', () async {
      const category =
          '{"id":"c","name":"Proteínas","purchaseIntervalDays":3,"monthlySpend":1200,"critical":true}';
      final repo = RestaurantRepository(api('[$category]'));
      expect((await repo.categories()).single.name, 'Proteínas');
      expect(calls.single.path, '/categories');

      final patching = RestaurantRepository(api(category));
      await patching.updateCategory('c', purchaseIntervalDays: 4);
      expect(calls.single.method, 'PATCH');
      expect(calls.single.path, '/categories/c');
      expect(calls.single.body, {'purchaseIntervalDays': 4});
    });
  });

  group('SupplyRepository', () {
    test('lists, details and creates supplies', () async {
      expect(
        (await SupplyRepository(api('[$supplyView]')).all()).single.id,
        'uuid',
      );
      expect(calls.single.path, '/supplies');

      final detailJson = (jsonDecode(supplyView) as Map<String, Object?>)
        ..['recommendation'] = jsonDecode(recommendation)
        ..['week'] = <Object>[]
        ..['recent'] = <Object>[]
        ..['lots'] = <Object>[];
      await SupplyRepository(api(jsonEncode(detailJson))).detail('uuid');
      expect(calls.single.path, '/supplies/uuid');

      await SupplyRepository(api(supplyView, status: 201))
          .create(const NewSupply(name: 'Pollo entero'));
      expect(calls.single.method, 'POST');
      expect(calls.single.body, {'name': 'Pollo entero'});
    });

    test('patches critical and stores phrases', () async {
      final repo = SupplyRepository(api('', status: 204));
      await repo.setCritical('s', critical: false);
      expect(calls.last.method, 'PATCH');
      expect(calls.last.path, '/supplies/s');
      expect(calls.last.body, {'critical': false});

      await repo.rememberPhrase('s', phrase: 'medio balde', amount: 6);
      expect(calls.last.method, 'PUT');
      expect(calls.last.path, '/supplies/s/phrases');
      expect(calls.last.body, {'phrase': 'medio balde', 'amount': 6});
    });

    test('resolves catalog terms', () async {
      final resolution = await SupplyRepository(api('{"kind":"unknown"}'))
          .resolve('huacatay');
      expect(resolution.candidates, isEmpty);
      expect(calls.single.path, '/catalog/resolve');
      expect(calls.single.query, {'term': 'huacatay'});
    });
  });

  group('RecordRepository', () {
    test('posts the close, no consumption and purchases', () async {
      final repo = RecordRepository(api('', status: 204));
      await repo.closeStock({'s': 2.5});
      expect(calls.last.path, '/stock-close');
      expect(calls.last.body, {
        'remaining': {'s': 2.5},
      });

      await repo.markNoConsumption();
      expect(calls.last.path, '/stock-close/none');
      expect(calls.last.body, '');

      final saving = RecordRepository(api('{"lots":1}', status: 201));
      final lots = await saving.savePurchase([
        PurchaseLine(
          supplyId: 's',
          quantity: 2,
          cost: 20,
          expiresOn: DateTime.utc(2026, 11, 19),
        ),
      ]);
      expect(lots, 1);
      expect(calls.single.path, '/purchases');
      expect(calls.single.body, {
        'lines': [
          {
            'supplyId': 's',
            'quantity': 2,
            'cost': 20,
            'expiresOn': '2026-11-19',
          },
        ],
      });
    });

    test('surfaces the server message on failure', () async {
      final repo = RecordRepository(
        api('Hay insumos que no son de este restaurante', status: 422),
      );
      await expectLater(
        repo.closeStock({'x': 1}),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            'Hay insumos que no son de este restaurante',
          ),
        ),
      );
    });
  });

  group('InsightRepository', () {
    test('reads today and savings', () async {
      await InsightRepository(
        api('{"day":"2026-11-16","alerts":[],"toBuy":[],"covered":[]}'),
      ).today();
      expect(calls.single.path, '/today');
      await InsightRepository(
        api('{"months":[],"current":0,"previous":0,"topWasted":[]}'),
      ).savings();
      expect(calls.single.path, '/savings');
    });
  });

  group('VoiceRepository', () {
    test('uploads the audio as multipart with its kind', () async {
      final file = await _tempAudio();
      final draft = await VoiceRepository(
        api('{"transcript":"quedan","items":[]}'),
      ).transcribe(kind: VoiceKind.close, audioPath: file);
      expect(draft.transcript, 'quedan');
      final request = calls.single.request;
      expect(calls.single.path, '/voice');
      expect(
        request.headers['Content-Type'],
        startsWith('multipart/form-data'),
      );
      expect(request.headers['Authorization'], 'Bearer token');
      expect(calls.single.body.toString(), contains('name="kind"'));
      expect(calls.single.body.toString(), contains('close'));
      expect(calls.single.body.toString(), contains('name="audio"'));
    });

    test('maps provider and configuration errors', () async {
      final file = await _tempAudio();
      await expectLater(
        VoiceRepository(
          api(
            'No se pudo procesar el dictado, inténtalo otra vez',
            status: 502,
          ),
        ).transcribe(kind: VoiceKind.purchase, audioPath: file),
        throwsA(
          isA<ApiException>().having((e) => e.isRetryable, 'retry', true),
        ),
      );
      await expectLater(
        VoiceRepository(
          api('El dictado por voz no está configurado', status: 503),
        ).transcribe(kind: VoiceKind.purchase, audioPath: file),
        throwsA(
          isA<ApiException>()
              .having((e) => e.isRetryable, 'retry', false)
              .having(
                (e) => e.message,
                'message',
                'El dictado por voz no está configurado',
              ),
        ),
      );
    });
  });
}

Future<String> _tempAudio() async {
  final file = await File(
    '${Directory.systemTemp.createTempSync('kilo').path}/audio.m4a',
  ).writeAsBytes([1, 2, 3]);
  return file.path;
}
