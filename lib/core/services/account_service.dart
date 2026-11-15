import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

const apiBaseUrl = String.fromEnvironment('MM_API_URL');

abstract class AccountStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

class SecureAccountStore implements AccountStore {
  const SecureAccountStore();

  static const _storage = FlutterSecureStorage();

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

class AccountUser {
  const AccountUser(
      {required this.id, required this.name, required this.email});

  final String id;
  final String name;
  final String email;

  factory AccountUser.fromJson(Map<String, dynamic> json) => AccountUser(
        id: json['id'] as String,
        name: json['display_name'] as String,
        email: json['email'] as String,
      );
}

class AccountException implements Exception {
  const AccountException(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() => message;
}

class AccountService {
  AccountService({http.Client? client, AccountStore? storage, String? baseUrl})
      : _client = client ?? http.Client(),
        _storage = storage ?? const SecureAccountStore(),
        _apiBaseUrl = baseUrl ?? apiBaseUrl;

  static const _tokenKey = 'mm.session.token';
  static const _ownerKey = 'mm.local.owner_id';

  final http.Client _client;
  final AccountStore _storage;
  final String _apiBaseUrl;

  bool get isConfigured => _apiBaseUrl.isNotEmpty;

  Uri get _base {
    if (_apiBaseUrl.isEmpty) {
      throw const AccountException('Servidor ainda não configurado neste app.');
    }
    final uri = Uri.tryParse(_apiBaseUrl);
    if (uri == null ||
        !(uri.scheme == 'https' ||
            (uri.scheme == 'http' &&
                (uri.host == 'localhost' || uri.host == '127.0.0.1')))) {
      throw const AccountException(
          'O endereço do servidor precisa usar HTTPS.');
    }
    return uri;
  }

  Uri _url(String path) => _base.resolve(path);

  Future<AccountUser?> restore() async {
    final token = await _storage.read(_tokenKey);
    if (token == null) return null;
    final response = await _send('GET', '/v1/me', token: token);
    if (response.statusCode == 401) {
      await _storage.delete(_tokenKey);
      return null;
    }
    _check(response);
    final user = AccountUser.fromJson(
        _object(_object(jsonDecode(response.body))['user']));
    await _checkLocalOwner(user.id);
    return user;
  }

  Future<AccountUser> register(String name, String email, String password) =>
      _authenticate('/v1/auth/register', {
        'display_name': name.trim(),
        'email': email.trim(),
        'password': password,
      });

  Future<AccountUser> login(String email, String password) =>
      _authenticate('/v1/auth/login', {
        'email': email.trim(),
        'password': password,
      });

  Future<AccountUser> _authenticate(
      String path, Map<String, String> body) async {
    final response = await _send('POST', path, body: body);
    _check(response);
    final result = _object(jsonDecode(response.body));
    final user = AccountUser.fromJson(_object(result['user']));
    final token = _object(result['session'])['token'] as String;
    try {
      await _checkLocalOwner(user.id);
    } on AccountException {
      try {
        await _send('POST', '/v1/auth/logout', token: token);
      } catch (_) {
        // O token nunca foi persistido neste aparelho.
      }
      rethrow;
    }
    await _storage.write(_tokenKey, token);
    // A associação só impede outra conta de adotar o banco local. Ela não envia
    // o histórico: isso terá um fluxo de importação/sincronização próprio.
    await _storage.write(_ownerKey, user.id);
    return user;
  }

  Future<void> _checkLocalOwner(String userID) async {
    final owner = await _storage.read(_ownerKey);
    if (owner != null && owner != userID) {
      throw const AccountException(
        'Este aparelho já tem dados vinculados a outra conta. Entre com a conta usada aqui.',
        code: 'local_account_mismatch',
      );
    }
  }

  Future<void> logout() async {
    final token = await _storage.read(_tokenKey);
    if (token != null) {
      final response = await _send('POST', '/v1/auth/logout', token: token);
      if (response.statusCode != 401) _check(response);
      await _storage.delete(_tokenKey);
    }
  }

  Future<http.Response> _send(String method, String path,
      {Map<String, String>? body, String? token}) async {
    try {
      final headers = <String, String>{
        if (body != null) 'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };
      final uri = _url(path);
      if (method == 'GET') return await _client.get(uri, headers: headers);
      return await _client.post(uri,
          headers: headers, body: body == null ? null : jsonEncode(body));
    } on AccountException {
      rethrow;
    } catch (_) {
      throw const AccountException(
          'Não foi possível falar com o servidor. Tente novamente.');
    }
  }

  void _check(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    try {
      final error = _object(_object(jsonDecode(response.body))['error']);
      throw AccountException(error['message'] as String,
          code: error['code'] as String?);
    } on AccountException {
      rethrow;
    } catch (_) {
      throw const AccountException(
          'O servidor não conseguiu concluir esta ação.');
    }
  }

  Map<String, dynamic> _object(Object? value) =>
      (value as Map).cast<String, dynamic>();
}
