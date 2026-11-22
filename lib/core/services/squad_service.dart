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
    final timeout = Duration(seconds: path == '/v1/ai/workouts' ? 90 : 30);
    return decode(await http.Response.fromStream(
            await client.send(request).timeout(timeout))
        .timeout(timeout));
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

  Future<Map<String, dynamic>> uploadAudio(XFile audio,
      {String? filename}) async {
    final bytes = await audio.readAsBytes();
    if (bytes.length > 15 * 1024 * 1024)
      throw const AccountException('Escolha um áudio de até 15 MB.');
    final upload = http.MultipartRequest('POST', url('/v1/tracks/upload'));
    upload.headers.addAll(await headers());
    upload.fields.addAll({
      'title':
          (filename ?? (audio.name.isEmpty ? 'Áudio do celular' : audio.name))
              .replaceFirst(RegExp(r'\.[^.]+$'), ''),
      'license': 'open-or-owned'
    });
    upload.files.add(http.MultipartFile.fromBytes('audio', bytes,
        filename: filename ?? (audio.name.isEmpty ? 'audio' : audio.name)));
    final result = decode(await http.Response.fromStream(
        await client.send(upload).timeout(const Duration(seconds: 60))));
    return Map<String, dynamic>.from(result['track']);
  }

  Future<void> publish(
      XFile photo, String caption, Map<String, dynamic>? track, String key,
      {Map<String, dynamic>? report, String? videoUrl}) async {
    if (report != null) {
      try {
        final capabilities = await request('GET', '/v1/story-capabilities');
        if (capabilities['workout_report_version'] != 1)
          throw const AccountException('Versão incompatível.');
      } catch (_) {
        throw const AccountException(
            'O servidor precisa ser atualizado para receber relatórios de treino. Nenhuma publicação foi enviada.');
      }
    }
    final upload = http.MultipartRequest('POST', url('/v1/stories'));
    upload.headers.addAll(await headers());
    upload.headers['Idempotency-Key'] = key;
    upload.fields['caption'] = caption;
    if (videoUrl != null && videoUrl.isNotEmpty)
      upload.fields['video_url'] = videoUrl;
    if (report != null) upload.fields['workout_report'] = jsonEncode(report);
    if (track != null) {
      upload.fields.addAll({
        'track_id': track['id'],
        'track_start_ms': '0',
        'track_duration_ms': '${(track['duration_ms'] as int).clamp(1, 15000)}'
      });
    }
    upload.files.add(http.MultipartFile.fromBytes(
        'photo', await photo.readAsBytes(),
        filename: photo.name.isEmpty ? 'story.png' : photo.name));
    decode(await http.Response.fromStream(
        await client.send(upload).timeout(const Duration(seconds: 60))));
  }
}
