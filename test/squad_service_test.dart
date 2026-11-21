import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker/core/services/account_service.dart';
import 'package:gym_tracker/core/services/squad_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'account_service_test.dart' show MemoryAccountStore;

void main() {
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
