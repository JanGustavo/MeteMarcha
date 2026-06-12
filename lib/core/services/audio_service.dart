// lib/core/services/audio_service.dart
//
// Coloque um arquivo "beep.mp3" em assets/sounds/.
// Se não existir, os erros são silenciados — o app continua funcionando.

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal() {
    _configureAudioContext();
  }

  void _configureAudioContext() {
    try {
      AudioPlayer.global.setAudioContext(AudioContext(
        android: AudioContextAndroid(
          isSpeakerphoneOn: true,
          stayAwake: true,
          contentType: AndroidContentType.sonification,
          usageType: AndroidUsageType.assistanceSonification,
          audioFocus: AndroidAudioFocus.gainTransientMayDuck,
        ),
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playback,
          options: const {
            AVAudioSessionOptions.mixWithOthers,
            AVAudioSessionOptions.duckOthers,
          },
        ),
      ));
    } catch (e) {
      debugPrint('Erro ao configurar AudioContext: $e');
    }
  }

  AudioPlayer? __player;
  AudioPlayer get _player => __player ??= AudioPlayer();
  bool? _audioAvailable;

  @visibleForTesting
  void setPlayer(AudioPlayer player) {
    __player = player;
  }

  @visibleForTesting
  void setAudioAvailable(bool available) {
    _audioAvailable = available;
  }

  /// Verifica se o arquivo de áudio está de fato disponível no bundle
  Future<void> _checkAudio() async {
    if (_audioAvailable != null) return;
    try {
      await rootBundle.load('assets/sounds/beep.mp3');
      _audioAvailable = true;
    } catch (_) {
      _audioAvailable = false;
    }
  }

  /// Bipe curto — série salva
  Future<void> beep() async {
    await _checkAudio();
    if (_audioAvailable != true) return;
    try {
      await _player.stop();
      await _player.play(AssetSource('sounds/beep.mp3'));
    } catch (_) {}
  }

  /// Dois bipes — descanso encerrado
  Future<void> restEnd() async {
    await _checkAudio();
    if (_audioAvailable != true) return;
    try {
      for (var i = 0; i < 2; i++) {
        await _player.stop();
        await _player.play(AssetSource('sounds/beep.mp3'));
        await Future.delayed(const Duration(milliseconds: 250));
      }
    } catch (_) {}
  }

  /// Três bipes — treino concluído
  Future<void> workoutDone() async {
    await _checkAudio();
    if (_audioAvailable != true) return;
    try {
      for (var i = 0; i < 3; i++) {
        await _player.stop();
        await _player.play(AssetSource('sounds/beep.mp3'));
        await Future.delayed(const Duration(milliseconds: 200));
      }
    } catch (_) {}
  }

  /// Quatro bipes rápidos — Recorde Pessoal (PR) batido!
  Future<void> prCelebration() async {
    await _checkAudio();
    if (_audioAvailable != true) return;
    try {
      for (var i = 0; i < 4; i++) {
        await _player.stop();
        await _player.play(AssetSource('sounds/beep.mp3'));
        await Future.delayed(const Duration(milliseconds: 150));
      }
    } catch (_) {}
  }

  void dispose() => __player?.dispose();
}
