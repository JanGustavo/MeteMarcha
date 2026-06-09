// lib/core/providers/rest_timer_provider.dart

import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/audio_service.dart';
import '../services/notification_service.dart';

class RestTimerState {
  final bool isActive;
  final int totalSeconds;
  final int remainingSeconds;
  final int? dayId;
  final String? dayName;
  final int? sessionId;
  final bool inWorkoutPage;

  RestTimerState({
    this.isActive = false,
    this.totalSeconds = 0,
    this.remainingSeconds = 0,
    this.dayId,
    this.dayName,
    this.sessionId,
    this.inWorkoutPage = false,
  });

  RestTimerState copyWith({
    bool? isActive,
    int? totalSeconds,
    int? remainingSeconds,
    int? dayId,
    String? dayName,
    int? sessionId,
    bool? inWorkoutPage,
  }) {
    return RestTimerState(
      isActive: isActive ?? this.isActive,
      totalSeconds: totalSeconds ?? this.totalSeconds,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      dayId: dayId ?? this.dayId,
      dayName: dayName ?? this.dayName,
      sessionId: sessionId ?? this.sessionId,
      inWorkoutPage: inWorkoutPage ?? this.inWorkoutPage,
    );
  }
}

class RestTimerNotifier extends StateNotifier<RestTimerState> with WidgetsBindingObserver {
  RestTimerNotifier() : super(RestTimerState()) {
    WidgetsBinding.instance.addObserver(this);
  }

  Timer? _timer;
  DateTime? _endTime;
  bool _isMinimized = false;

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycleState) {
    _isMinimized = lifecycleState == AppLifecycleState.paused ||
        lifecycleState == AppLifecycleState.inactive;

    if (lifecycleState == AppLifecycleState.resumed) {
      NotificationService().cancelNotification();
      if (state.isActive) {
        _updateRemainingTime();
      }
    } else if (_isMinimized && state.isActive) {
      NotificationService().showRestTimer(state.remainingSeconds);
    }
  }

  void startRest(int seconds, {required int dayId, required String dayName, required int sessionId}) {
    _timer?.cancel();
    _endTime = DateTime.now().add(Duration(seconds: seconds));

    state = RestTimerState(
      isActive: true,
      totalSeconds: seconds,
      remainingSeconds: seconds,
      dayId: dayId,
      dayName: dayName,
      sessionId: sessionId,
      inWorkoutPage: state.inWorkoutPage,
    );

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      _updateRemainingTime();
    });

    if (_isMinimized) {
      NotificationService().showRestTimer(seconds);
    }
  }

  void _updateRemainingTime() {
    if (_endTime == null) {
      _timer?.cancel();
      return;
    }

    final now = DateTime.now();
    final difference = _endTime!.difference(now).inSeconds;

    if (difference <= 0) {
      _timer?.cancel();
      _onTimerFinished();
    } else {
      state = state.copyWith(remainingSeconds: difference);

      if (_isMinimized) {
        NotificationService().showRestTimer(difference);
      }
    }
  }

  void cancelRest() {
    _timer?.cancel();
    _endTime = null;
    state = RestTimerState(inWorkoutPage: state.inWorkoutPage);
    NotificationService().cancelNotification();
  }

  void setInWorkoutPage(bool inPage) {
    state = state.copyWith(inWorkoutPage: inPage);
  }

  void _onTimerFinished() {
    _endTime = null;
    state = state.copyWith(isActive: false, remainingSeconds: 0);
    
    // Reproduz áudio e vibração
    AudioService().restEnd();

    // Mostra notificação de finalização do descanso
    NotificationService().showRestEnded();

    // Se estiver no aplicativo (foreground), abre a tela de treino
    if (!_isMinimized) {
      NotificationService.openActiveWorkout();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}

final restTimerProvider = StateNotifierProvider<RestTimerNotifier, RestTimerState>((ref) {
  return RestTimerNotifier();
});
