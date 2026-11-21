import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'account_service.dart';

class SquadService {
  SquadService({http.Client? client, AccountStore? storage})
      : client = client ?? http.Client(),
        storage = storage ?? const SecureAccountStore();
  final http.Client client;
  final AccountStore storage;
  Future<Map<String, String>> headers() async {
    final token = await storage.read('mm.session.token');
    if (token == null)
      throw const AccountException(
          'Entre na sua conta para acessar os squads.');
    return {'Authorization': 'Bearer $token'};
  }

  Uri url(String path) {
    final uri = Uri.parse(apiBaseUrl).resolve(path);
    if (uri.origin != Uri.parse(apiBaseUrl).origin)
      throw const AccountException('Endereço de mídia inválido.');
    return uri;
  }

  Future<Map<String, dynamic>> request(String method, String path,
      [Map<String, dynamic>? body]) async {
    final request = http.Request(method, url(path));
    request.headers.addAll(await headers());
    if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);
    }
    return decode(await http.Response.fromStream(
        await client.send(request).timeout(const Duration(seconds: 30))));
  }

  Map<String, dynamic> decode(http.Response response) {
    final data = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 300)
      throw AccountException(
          data['error']?['message'] ?? 'Não foi possível concluir a ação.',
          code: data['error']?['code']);
    return data;
  }

  Future<void> publish(XFile photo, String caption, Map<String, dynamic>? track,
      String key) async {
    final request = http.MultipartRequest('POST', url('/v1/stories'));
    request.headers.addAll(await headers());
    request.headers['Idempotency-Key'] = key;
    request.fields['caption'] = caption;
    if (track != null) {
      request.fields.addAll({
        'track_id': track['id'],
        'track_start_ms': '0',
        'track_duration_ms': '${(track['duration_ms'] as int).clamp(1, 15000)}'
      });
    }
    request.files.add(http.MultipartFile.fromBytes(
        'photo', await photo.readAsBytes(),
        filename: photo.name));
    decode(await http.Response.fromStream(
        await client.send(request).timeout(const Duration(seconds: 60))));
  }
}
