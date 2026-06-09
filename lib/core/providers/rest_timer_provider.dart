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
  bool _isMinimized = false;

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycleState) {
    _isMinimized = lifecycleState == AppLifecycleState.paused ||
        lifecycleState == AppLifecycleState.inactive;

    if (lifecycleState == AppLifecycleState.resumed) {
      NotificationService().cancelNotification();
    } else if (_isMinimized && state.isActive) {
      NotificationService().showRestTimer(state.remainingSeconds);
    }
  }

  void startRest(int seconds, {required int dayId, required String dayName, required int sessionId}) {
    _timer?.cancel();
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
      if (state.remainingSeconds <= 1) {
        t.cancel();
        _onTimerFinished();
      } else {
        final newRemaining = state.remainingSeconds - 1;
        state = state.copyWith(remainingSeconds: newRemaining);

        if (_isMinimized) {
          NotificationService().showRestTimer(newRemaining);
        }
      }
    });

    if (_isMinimized) {
      NotificationService().showRestTimer(seconds);
    }
  }

  void cancelRest() {
    _timer?.cancel();
    state = RestTimerState(inWorkoutPage: state.inWorkoutPage);
    NotificationService().cancelNotification();
  }

  void setInWorkoutPage(bool inPage) {
    state = state.copyWith(inWorkoutPage: inPage);
  }

  void _onTimerFinished() {
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
