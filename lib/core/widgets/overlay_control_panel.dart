// lib/core/widgets/overlay_control_panel.dart

import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

class OverlayControlPanel extends StatefulWidget {
  const OverlayControlPanel({super.key});

  @override
  State<OverlayControlPanel> createState() => _OverlayControlPanelState();
}

class _OverlayControlPanelState extends State<OverlayControlPanel> {
  // Estado local sincronizado do treino
  String exerciseName = "Carregando...";
  double weight = 0.0;
  int reps = 10;
  int currentSerie = 1;
  int exerciseIndex = 0;
  List<String> exercises = [];
  List<bool> exercisesCompleted = [];

  // Rest Timer
  int timerSeconds = 0;
  int timerMax = 0;
  bool isResting = false;

  // Estado da Janela Flutuante
  bool isExpanded = true;
  bool showExerciseList = false;

  @override
  void initState() {
    super.initState();

    // Escuta atualizações de estado vindas do app principal
    FlutterOverlayWindow.overlayListener.listen((event) {
      if (event == null) return;
      try {
        final Map<String, dynamic> msg = event is Map
            ? Map<String, dynamic>.from(event)
            : Map<String, dynamic>.from(jsonDecode(event.toString()));

        if (msg['type'] == 'state_update') {
          setState(() {
            exerciseName = msg['exerciseName'] ?? 'Exercício';
            weight = (msg['weight'] as num?)?.toDouble() ?? 0.0;
            reps = msg['reps'] as int? ?? 10;
            exerciseIndex = msg['exerciseIndex'] as int? ?? 0;
            exercises = List<String>.from(msg['exercises'] ?? []);
            exercisesCompleted = List<bool>.from(msg['exercisesCompleted'] ?? []);
            currentSerie = msg['currentSerie'] as int? ?? 1;
            timerSeconds = msg['timerSeconds'] as int? ?? 0;
            timerMax = msg['timerMax'] as int? ?? 0;
            isResting = msg['isResting'] as bool? ?? false;
          });
        }
      } catch (e) {
        // ignore: avoid_print
        print('Erro no overlay ao processar estado: $e');
      }
    });
  }

  void _sendAction(String type, [Map<String, dynamic>? extra]) {
    final Map<String, dynamic> msg = {'type': type};
    if (extra != null) {
      msg.addAll(extra);
    }
    FlutterOverlayWindow.shareData(msg);
  }

  Future<void> _minimize() async {
    setState(() {
      isExpanded = false;
      showExerciseList = false;
    });
    final double pixelRatio = MediaQuery.of(context).devicePixelRatio;
    await FlutterOverlayWindow.resizeOverlay(
      (76 * pixelRatio).round(),
      (76 * pixelRatio).round(),
      true,
    );
  }

  Future<void> _maximize() async {
    setState(() {
      isExpanded = true;
    });
    final double pixelRatio = MediaQuery.of(context).devicePixelRatio;
    await FlutterOverlayWindow.resizeOverlay(
      (330 * pixelRatio).round(),
      (390 * pixelRatio).round(),
      true,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!isExpanded) {
      return _buildMinimizedBubble();
    }

    return _buildExpandedPanel();
  }

  Widget _buildMinimizedBubble() {
    return GestureDetector(
      onTap: _maximize,
      child: Center(
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: const Color(0xFFE53935),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.8),
              width: 2.0,
            ),
          ),
          child: Center(
            child: isResting
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        '⏳',
                        style: TextStyle(fontSize: 14),
                      ),
                      Text(
                        '${timerSeconds}s',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  )
                : const Text(
                    '💪',
                    style: TextStyle(fontSize: 28),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedPanel() {
    return Center(
      child: Container(
        width: 320,
        height: 380,
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 15,
              spreadRadius: 2,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E).withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                  width: 1.0,
                ),
              ),
              child: Column(
                children: [
                  // Cabeçalho (Title Bar)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: const BoxDecoration(
                              color: Color(0xFFE53935),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Text(
                                '🎵',
                                style: TextStyle(fontSize: 12, color: Colors.white),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'TREINO EM PROGRESSO',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: _minimize,
                        icon: const Icon(Icons.close, color: Colors.grey, size: 18),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Caixa do Exercício com seletor
                  Stack(
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            showExerciseList = !showExerciseList;
                          });
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.05),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  exerciseName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Icon(
                                showExerciseList ? Icons.keyboard_arrow_up : Icons.edit,
                                color: const Color(0xFFE53935),
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Lista Dropdown Suspensa de Exercícios
                      if (showExerciseList && exercises.isNotEmpty)
                        Positioned(
                          top: 48,
                          left: 0,
                          right: 0,
                          child: Container(
                            height: 180,
                            decoration: BoxDecoration(
                              color: const Color(0xFF2A2A2A),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.1),
                              ),
                            ),
                            child: ListView.builder(
                              itemCount: exercises.length,
                              itemBuilder: (context, index) {
                                final isCurrent = index == exerciseIndex;
                                final isCompleted = index < exercisesCompleted.length && exercisesCompleted[index];
                                return ListTile(
                                  dense: true,
                                  title: Text(
                                    exercises[index],
                                    style: TextStyle(
                                      color: isCurrent
                                          ? const Color(0xFFE53935)
                                          : Colors.white.withValues(alpha: 0.8),
                                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                  trailing: isCompleted
                                      ? const Icon(Icons.check_circle, color: Colors.green, size: 16)
                                      : null,
                                  onTap: () {
                                    _sendAction('select_exercise', {'index': index});
                                    setState(() {
                                      showExerciseList = false;
                                    });
                                  },
                                );
                              },
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Área de Carga e Repetição
                  Expanded(
                    child: Row(
                      children: [
                        // Carga (Peso)
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.02),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.02),
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'Peso (kg)',
                                  style: TextStyle(color: Colors.grey, fontSize: 11),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          if (weight >= 0.5) weight -= 0.5;
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.08),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.remove, color: Colors.white, size: 14),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${weight.toStringAsFixed(1)} kg',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          weight += 0.5;
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.08),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.add, color: Colors.white, size: 14),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Repetições
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.02),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.02),
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'Repetições',
                                  style: TextStyle(color: Colors.grey, fontSize: 11),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          if (reps > 1) reps--;
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.08),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.remove, color: Colors.white, size: 14),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      '$reps',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          reps++;
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.08),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.add, color: Colors.white, size: 14),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Rest Timer status bar se ativo
                  if (isResting)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            '⏳ Descanso: ',
                            style: TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${timerSeconds}s restantes',
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),

                  // Botões de Ação
                  Row(
                    children: [
                      // Salvar Série
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            _sendAction('save_series', {'peso': weight, 'reps': reps});
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: const Icon(Icons.check, color: Colors.white, size: 16),
                          label: const Text(
                            'SALVAR SÉRIE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Próximo
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            _sendAction('next_exercise');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE53935),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: const Icon(Icons.arrow_forward, color: Colors.white, size: 16),
                          label: const Text(
                            'PRÓXIMO',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Clique para abrir o app completo
                  GestureDetector(
                    onTap: () {
                      _sendAction('open_app');
                    },
                    child: Text(
                      'Clique para abrir o app completo',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 10,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
