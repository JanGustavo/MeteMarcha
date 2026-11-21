import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker/core/services/account_service.dart';
import 'package:gym_tracker/core/services/squad_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'account_service_test.dart' show MemoryAccountStore;

void main() {
  test('não publica a capa sozinha quando a API não aceita relatórios',
      () async {
    final store = MemoryAccountStore();
    store.values['mm.session.token'] = 'session';
    var calls = 0;
    final api = SquadService(
        storage: store,
        client: MockClient((request) async {
          calls++;
          expect(request.method, 'GET');
          expect(request.url.path, '/v1/story-capabilities');
          return http.Response('Not found', 404);
        }));
    await expectLater(
        api.publish(XFile.fromData(Uint8List.fromList([1, 2, 3]), name: 'cover.png'), ' ', null,
            'report-key',
            report: {'version': 1}),
        throwsA(isA<AccountException>()));
    expect(calls, 1);
  });

  test('squads usa a sessão existente e mantém os erros da API', () async {
    final store = MemoryAccountStore();
    store.values['mm.session.token'] = 'session';
    final api = SquadService(
        storage: store,
        client: MockClient((request) async {
          expect(request.headers['Authorization'], 'Bearer session');
          expect(request.url.path, '/v1/groups/me');
          return http.Response(
              '{"error":{"code":"not_in_group","message":"Sem squad"}}', 403);
        }));
    await expectLater(
        api.request('GET', '/v1/groups/me'),
        throwsA(isA<AccountException>()
            .having((e) => e.code, 'code', 'not_in_group')));
  });
  test('mídia não envia a sessão para outra origem', () {
    expect(() => SquadService().url('https://example.org/photo'),
        throwsA(isA<AccountException>()));
  });
}
