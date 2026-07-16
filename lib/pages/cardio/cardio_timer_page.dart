// lib/pages/cardio/cardio_timer_page.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/app_database.dart';
import '../../core/providers/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/audio_service.dart';

class CardioTimerPage extends ConsumerStatefulWidget {
  const CardioTimerPage({super.key});

  @override
  ConsumerState<CardioTimerPage> createState() => _CardioTimerPageState();
}

class _CardioTimerPageState extends ConsumerState<CardioTimerPage> {
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;
  late final PageController _pageController;
  
  String _selectedType = 'Esteira';
  String _selectedIntensity = 'Moderada';
  
  final List<Map<String, dynamic>> _cardioTypes = [
    {'name': 'Esteira', 'icon': Icons.directions_run_rounded},
    {'name': 'Bicicleta', 'icon': Icons.pedal_bike_rounded},
    {'name': 'Escada', 'icon': Icons.stairs_rounded},
    {'name': 'Elíptico', 'icon': Icons.double_arrow_rounded},
    {'name': 'Corrida de Rua', 'icon': Icons.add_road_rounded},
    {'name': 'Outro', 'icon': Icons.sports_gymnastics_rounded},
  ];

  final List<String> _intensities = ['Leve', 'Moderada', 'Alta'];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.5, initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startStopwatch() {
    AudioService().playClick();
    setState(() {
      _stopwatch.start();
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {});
      });
    });
  }

  void _pauseStopwatch() {
    AudioService().playClick();
    setState(() {
      _stopwatch.stop();
      _timer?.cancel();
    });
  }

  void _stopAndSave() {
    AudioService().playClick();
    _stopwatch.stop();
    _timer?.cancel();

    final elapsedSeconds = _stopwatch.elapsed.inSeconds;
    if (elapsedSeconds < 5) {
      // Evita salvar treinos extremamente curtos por acidente
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: context.cardColor,
          title: const Text('Tempo muito curto'),
          content: const Text('Sua sessão de cárdio deve ter pelo menos 5 segundos para ser registrada.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    _showSaveDialog(elapsedSeconds);
  }

  void _showSaveDialog(int elapsedSeconds) {
    final distanceController = TextEditingController();
    final caloriesController = TextEditingController();
    
    final minutes = elapsedSeconds ~/ 60;
    final seconds = elapsedSeconds % 60;
    final timeStr = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.cardColor,
        title: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: AppColors.primaryLight, size: 24),
            const SizedBox(width: 8),
            const Text('Concluir Cárdio! 🎉'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Excelente esforço! Você correu/pedalou por:',
                style: TextStyle(color: context.onSurface, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  timeStr,
                  style: TextStyle(
                    color: context.onBackground,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: distanceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Distância (Km) - Opcional',
                  hintText: 'ex: 3.5',
                  prefixIcon: Icon(Icons.edit_road_rounded),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: caloriesController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Calorias (kcal) - Opcional',
                  hintText: 'ex: 280',
                  prefixIcon: Icon(Icons.local_fire_department_rounded),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _stopwatch.start();
                _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
                  setState(() {});
                });
              });
            },
            child: const Text('Voltar ao Cárdio'),
          ),
          ElevatedButton(
            onPressed: () async {
              final distance = double.tryParse(distanceController.text.replaceAll(',', '.'));
              final calories = int.tryParse(caloriesController.text);
              
              final entry = CardiosCompanion.insert(
                data: DateTime.now().toIso8601String(),
                tipo: _selectedType,
                duracaoSegundos: elapsedSeconds,
                distanciaKm: Value(distance),
                calorias: Value(calories),
                intensidade: Value(_selectedIntensity),
              );

              await ref.read(cardioDaoProvider).insertCardio(entry);
              
              // Toca som de treino concluído
              try {
                AudioService().workoutDone();
              } catch (_) {}

              if (ctx.mounted) {
                Navigator.pop(ctx); // fecha dialog
                Navigator.pop(context); // volta para home
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Sessão de cárdio salva com sucesso! 🏃'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  String _formatTime(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return duration.inHours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final elapsed = _stopwatch.elapsed;
    final isRunning = _stopwatch.isRunning;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cronômetro de Cárdio 🏃'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            // Tipo de cárdio selector
            SizedBox(
              height: 130,
              child: PageView.builder(
                controller: _pageController,
                itemCount: _cardioTypes.length,
                onPageChanged: (index) {
                  AudioService().playClick();
                  setState(() {
                    _selectedType = _cardioTypes[index]['name'];
                  });
                },
                itemBuilder: (context, index) {
                  final type = _cardioTypes[index];
                  final isSelected = _selectedType == type['name'];

                  return AnimatedBuilder(
                    animation: _pageController,
                    builder: (context, child) {
                      double value = 1.0;
                      if (_pageController.position.haveDimensions) {
                        value = _pageController.page! - index;
                        value = (1 - (value.abs() * 0.15)).clamp(0.85, 1.0);
                      } else {
                        value = index == 0 ? 1.0 : 0.85;
                      }

                      return Transform.scale(
                        scale: value,
                        child: child,
                      );
                    },
                    child: GestureDetector(
                      onTap: () {
                        _pageController.animateToPage(
                          index,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? const LinearGradient(
                                  colors: [AppColors.primary, AppColors.primaryLight],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : null,
                          color: isSelected ? null : context.cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? Colors.transparent : context.divider,
                            width: 1.5,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  )
                                ]
                              : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              type['icon'],
                              size: 36,
                              color: isSelected ? Colors.white : context.onSurface,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              type['name'],
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? Colors.white : context.onBackground,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),

            // Intensidade selector
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: _intensities.map((intensity) {
                  final isSelected = _selectedIntensity == intensity;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: ChoiceChip(
                      label: Text(intensity),
                      selected: isSelected,
                      selectedColor: intensity == 'Leve' 
                          ? Colors.teal.shade700 
                          : (intensity == 'Moderada' ? Colors.orange.shade700 : Colors.red.shade700),
                      onSelected: (selected) {
                        if (selected) {
                          AudioService().playClick();
                          setState(() {
                            _selectedIntensity = intensity;
                          });
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),

            const Spacer(),

            // Timer display
            Center(
              child: Column(
                children: [
                  Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: context.divider.withValues(alpha: 0.05),
                      border: Border.all(
                        color: isRunning ? AppColors.primaryLight : context.divider,
                        width: 4,
                      ),
                      boxShadow: isRunning
                          ? [
                              BoxShadow(
                                color: AppColors.primaryLight.withValues(alpha: 0.15),
                                blurRadius: 20,
                                spreadRadius: 5,
                              )
                            ]
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        _formatTime(elapsed),
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isRunning ? 'CÁRDIO EM ANDAMENTO' : 'PAUSADO',
                    style: TextStyle(
                      color: isRunning ? AppColors.primaryLight : context.onSurface,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Controls buttons
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Finish Button (Only active if elapsed time is > 0)
                  if (elapsed.inSeconds > 0)
                    FloatingActionButton.large(
                      heroTag: 'finish_cardio',
                      onPressed: _stopAndSave,
                      backgroundColor: Colors.red.shade800,
                      foregroundColor: Colors.white,
                      child: const Icon(Icons.stop_rounded, size: 36),
                    ),
                  
                  // Play / Pause Button
                  FloatingActionButton.large(
                    heroTag: 'play_pause_cardio',
                    onPressed: isRunning ? _pauseStopwatch : _startStopwatch,
                    backgroundColor: isRunning ? Colors.amber.shade700 : AppColors.primary,
                    foregroundColor: Colors.white,
                    child: Icon(isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 40),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
