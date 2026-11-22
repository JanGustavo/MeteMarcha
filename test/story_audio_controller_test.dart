import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gym_tracker/core/services/story_audio_controller.dart';

class FakeMusicPlayer extends AudioPlayer {
  final volumes = <double>[];
  int plays = 0, stops = 0;
  AudioContext? context;
  @override
  Future<void> setAudioContext(AudioContext ctx) async {
    context = ctx;
  }

  @override
  Future<void> setVolume(double value) async {
    volumes.add(value);
  }

  @override
  Future<void> play(Source source,
      {double? volume,
      double? balance,
      AudioContext? ctx,
      Duration? position,
      PlayerMode? mode}) async {
    plays++;
    if (volume != null) volumes.add(volume);
  }

  @override
  Future<void> stop() async {
    stops++;
  }

  @override
  Future<void> dispose() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    for (final name in [
      'xyz.luan/audioplayers',
      'xyz.luan/audioplayers.global'
    ]) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(MethodChannel(name), (_) async => null);
    }
  });
  test('volume zero silencia, volume baixo é aplicado e só um story toca',
      () async {
    final a = FakeMusicPlayer(), b = FakeMusicPlayer();
    StoryAudioController controller(FakeMusicPlayer p) => StoryAudioController(
        loadBytes: () async => Uint8List.fromList([1]),
        start: Duration.zero,
        duration: const Duration(seconds: 15),
        player: p);
    final first = controller(a), second = controller(b);
    await first.activate();
    expect(a.plays, 1);
    expect(a.context?.android.usageType, AndroidUsageType.media);
    await first.setVolume(0);
    expect(a.volumes.last, 0);
    await first.setVolume(.1);
    expect(a.volumes.last, closeTo(.01, .0001));
    await first.toggleMute();
    expect(a.volumes.last, 0);
    await second.activate();
    expect(first.playing, isFalse);
    expect(second.playing, isTrue);
    expect(a.stops, greaterThan(0));
    await second.setVolume(0);
    await second.toggleMute();
    expect(second.volume, greaterThan(0));
    expect((await SharedPreferences.getInstance()).getDouble('mm.story.volume'),
        second.volume);
    await second.stop();
    await second.activate();
    expect(b.volumes.last, greaterThan(0));
    await second.stop();
    first.dispose();
    second.dispose();
  });
}
