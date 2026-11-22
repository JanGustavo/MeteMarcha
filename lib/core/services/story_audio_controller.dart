import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

AudioContext mediaAudioContext() => AudioContext(
    android: const AudioContextAndroid(
        isSpeakerphoneOn: false,
        stayAwake: true,
        contentType: AndroidContentType.music,
        usageType: AndroidUsageType.media,
        audioFocus: AndroidAudioFocus.gain),
    iOS: AudioContextIOS(category: AVAudioSessionCategory.playback));

class StoryAudioController extends ChangeNotifier with WidgetsBindingObserver {
  StoryAudioController(
      {required this.loadBytes,
      required this.start,
      required this.duration,
      AudioPlayer? player})
      : player = player ?? AudioPlayer() {
    WidgetsBinding.instance.addObserver(this);
  }
  final Future<Uint8List> Function() loadBytes;
  final Duration start, duration;
  final AudioPlayer player;
  static StoryAudioController? current;
  bool playing = false, loading = false, muted = false, disposed = false;
  double volume = .5;
  String? error;
  Timer? timer;
  Uint8List? bytes;
  int generation = 0;
  bool active = false;
  void changed() {
    if (!disposed) notifyListeners();
  }

  Future<void> activate() async {
    if (disposed || loading || playing) return;
    active = true;
    final request = ++generation;
    final previous = current;
    if (previous != null && previous != this) await previous.stop();
    current = this;
    loading = true;
    error = null;
    changed();
    try {
      final prefs = await SharedPreferences.getInstance();
      muted = prefs.getBool('mm.story.muted') ?? false;
      volume = (prefs.getDouble('mm.story.volume') ?? .5).clamp(0, 1);
      bytes ??= await loadBytes();
      if (disposed || request != generation || !active) return;
      await player.setAudioContext(mediaAudioContext());
      await player.play(BytesSource(bytes!),
          volume: muted ? 0 : volume * volume, position: start);
      if (disposed || request != generation || !active) {
        await player.stop();
        return;
      }
      playing = true;
      timer?.cancel();
      timer = Timer(duration, () async {
        await player.stop();
        playing = false;
        if (active && !disposed) await activate();
      });
    } catch (_) {
      error = 'Não foi possível tocar esta música.';
    } finally {
      if (!disposed && request == generation) {
        loading = false;
        changed();
      }
    }
  }

  Future<void> stop() async {
    if (disposed) return;
    active = false;
    generation++;
    timer?.cancel();
    loading = false;
    playing = false;
    try {
      await player.stop();
    } catch (_) {}
    if (current == this) current = null;
    changed();
  }

  Future<void> toggleMute() async {
    if (volume == 0) {
      volume = (await SharedPreferences.getInstance())
              .getDouble('mm.story.last_volume') ??
          .5;
      muted = false;
    } else {
      muted = !muted;
    }
    await player.setVolume(muted ? 0 : volume * volume);
    await (await SharedPreferences.getInstance())
        .setBool('mm.story.muted', muted);
    await (await SharedPreferences.getInstance())
        .setDouble('mm.story.volume', volume);
    changed();
  }

  Future<void> setVolume(double value) async {
    volume = value.clamp(0, 1);
    muted = volume == 0;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('mm.story.muted', muted);
    if (volume > 0) await prefs.setDouble('mm.story.last_volume', volume);
    await player.setVolume(muted ? 0 : volume * volume);
    await (await SharedPreferences.getInstance())
        .setDouble('mm.story.volume', volume);
    changed();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) stop();
  }

  @override
  void dispose() {
    disposed = true;
    generation++;
    timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    if (current == this) current = null;
    player.dispose();
    super.dispose();
  }
}
