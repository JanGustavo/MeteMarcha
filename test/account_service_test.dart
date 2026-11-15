import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gym_tracker/core/services/account_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class MemoryAccountStore implements AccountStore {
  final values = <String, String>{};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;

  @override
  Future<void> delete(String key) async {
    values.remove(key);
  }
}

Map<String, Object> authBody(String id) => {
      'user': {'id': id, 'display_name': 'Ana', 'email': 'ana@example.com'},
      'session': {
        'token': 'secret-token',
        'expires_at': '2026-12-15T00:00:00Z'
      },
    };

void main() {
  test('cadastro usa a API e guarda a sessão e a identidade local', () async {
    final store = MemoryAccountStore();
    final service = AccountService(
      baseUrl: 'https://example.com',
      storage: store,
      client: MockClient((request) async {
        expect(request.url.path, '/v1/auth/register');
        expect(jsonDecode(request.body), {
          'display_name': 'Ana',
          'email': 'ana@example.com',
          'password': 'senha-segura',
        });
        return http.Response(jsonEncode(authBody('user-1')), 201);
      }),
    );
    final user =
        await service.register(' Ana ', ' ana@example.com ', 'senha-segura');
    expect(user.id, 'user-1');
    expect(store.values['mm.session.token'], 'secret-token');
    expect(store.values['mm.local.owner_id'], 'user-1');
  });

  test('não associa dados locais a uma conta diferente', () async {
    final store = MemoryAccountStore()..values['mm.local.owner_id'] = 'user-1';
    final calls = <String>[];
    final service = AccountService(
      baseUrl: 'https://example.com',
      storage: store,
      client: MockClient((request) async {
        calls.add(request.url.path);
        if (request.url.path == '/v1/auth/logout') {
          return http.Response('', 204);
        }
        return http.Response(jsonEncode(authBody('user-2')), 200);
      }),
    );
    await expectLater(
        service.login('ana@example.com', 'senha-segura'),
        throwsA(isA<AccountException>()
            .having((e) => e.code, 'code', 'local_account_mismatch')));
    expect(store.values['mm.session.token'], isNull);
    expect(calls, ['/v1/auth/login', '/v1/auth/logout']);
  });

  test('sessão expirada é apagada; falha de rede mantém o token', () async {
    final store = MemoryAccountStore()
      ..values['mm.session.token'] = 'secret-token';
    final expired = AccountService(
      baseUrl: 'https://example.com',
      storage: store,
      client: MockClient((_) async => http.Response(
          '{"error":{"code":"unauthorized","message":"Expirada"}}', 401)),
    );
    expect(await expired.restore(), isNull);
    expect(store.values['mm.session.token'], isNull);

    store.values['mm.session.token'] = 'secret-token';
    final offline = AccountService(
      baseUrl: 'https://example.com',
      storage: store,
      client: MockClient((_) => Future.error(Exception('offline'))),
    );
    await expectLater(offline.restore(), throwsA(isA<AccountException>()));
    expect(store.values['mm.session.token'], 'secret-token');
  });
}
