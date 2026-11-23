import '../../main.dart';
import '../providers/providers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SquadInviteService {
  static const channel = MethodChannel('dev.jangustavo.metemarcha/invites');
  static final pending = ValueNotifier<String?>(null);
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    pending.value = prefs.getString('mm.pending.invite');
    if (pending.value != null)
      globalProviderContainer.read(homeTabProvider.notifier).state = 2;
    if (kIsWeb) {
      await receive(Uri.base.toString());
      return;
    }
    if (defaultTargetPlatform != TargetPlatform.android) return;
    channel.setMethodCallHandler((call) async {
      if (call.method == 'invite') await receive(call.arguments as String?);
    });
    await receive(await channel.invokeMethod<String>('initialLink'));
  }

  static Future<void> receive(String? raw) async {
    final uri = raw == null ? null : Uri.tryParse(raw);
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host != 'api.metemarcha.jangustavo.me' ||
        uri.path != '/invite') return;
    final code = uri.queryParameters['code'];
    if (code == null || !RegExp(r'^[a-zA-Z0-9_-]{8,100}$').hasMatch(code))
      return;
    await (await SharedPreferences.getInstance())
        .setString('mm.pending.invite', code);
    globalProviderContainer.read(homeTabProvider.notifier).state = 2;
    pending.value = code;
  }

  static Future<void> clear() async {
    await (await SharedPreferences.getInstance()).remove('mm.pending.invite');
    pending.value = null;
  }
}
