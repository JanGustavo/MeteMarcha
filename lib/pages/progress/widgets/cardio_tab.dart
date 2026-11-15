import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:gym_tracker/core/database/app_database.dart';
import 'package:gym_tracker/core/providers/providers.dart';
import 'package:gym_tracker/core/theme/app_theme.dart';
import 'package:gym_tracker/pages/progress/widgets/cardio_progress_chart.dart';

class CardioTab extends ConsumerStatefulWidget {
  const CardioTab({super.key});

  @override
  ConsumerState<CardioTab> createState() => _CardioTabState();
}

class _CardioTabState extends ConsumerState<CardioTab> {
  String _selectedTypeFilter = 'Todos';
  String _selectedSortOption = 'Data (Mais recente)';

  void _confirmDeleteCardio(BuildContext context, int id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.cardColor,
        title: const Text('Excluir registro'),
        content: const Text('Deseja realmente excluir este treino de cárdio?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              await ref.read(cardioDaoProvider).deleteCardio(id);
              if (ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Registro de cárdio excluído.'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cardiosAsync = ref.watch(cardiosProvider);
    final weeklyGoal = ref.watch(weeklyCardioGoalProvider);
    final dateFormatter = DateFormat('dd/MM/yyyy HH:mm');

    return cardiosAsync.when(
      data: (cardios) {
        // Calculate weekly goal progress
        final now = DateTime.now();
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final monday = DateTime(
          startOfWeek.year,
          startOfWeek.month,
          startOfWeek.day,
          0,
          0,
          0,
        );

        final thisWeekCardios = cardios.where((c) {
          final date = DateTime.tryParse(c.data);
          if (date == null) return false;
          return date.isAfter(monday.subtract(const Duration(seconds: 1)));
        }).toList();

        final totalSecondsThisWeek = thisWeekCardios.fold<int>(
          0,
          (sum, c) => sum + c.duracaoSegundos,
        );
        final totalMinutesThisWeek = totalSecondsThisWeek ~/ 60;
        final percent = weeklyGoal > 0
            ? (totalMinutesThisWeek / weeklyGoal).clamp(0.0, 1.0)
            : 0.0;
        final percentFormatted = (percent * 100).toStringAsFixed(0);

        // Apply filters and sorting to historical list
        List<Cardio> filteredAndSorted = List.from(cardios);

        if (_selectedTypeFilter != 'Todos') {
          filteredAndSorted = filteredAndSorted
              .where((c) => c.tipo == _selectedTypeFilter)
              .toList();
        }

        switch (_selectedSortOption) {
          case 'Data (Mais recente)':
            filteredAndSorted.sort((a, b) => b.data.compareTo(a.data));
            break;
          case 'Data (Mais antiga)':
            filteredAndSorted.sort((a, b) => a.data.compareTo(b.data));
            break;
          case 'Duração (Maior)':
            filteredAndSorted.sort(
              (a, b) => b.duracaoSegundos.compareTo(a.duracaoSegundos),
            );
            break;
          case 'Duração (Menor)':
            filteredAndSorted.sort(
              (a, b) => a.duracaoSegundos.compareTo(b.duracaoSegundos),
            );
            break;
          case 'Distância (Maior)':
            filteredAndSorted.sort((a, b) {
              final distA = a.distanciaKm ?? 0.0;
              final distB = b.distanciaKm ?? 0.0;
              return distB.compareTo(distA);
            });
            break;
          case 'Calorias (Maior)':
            filteredAndSorted.sort((a, b) {
              final calA = a.calorias ?? 0;
              final calB = b.calorias ?? 0;
              return calB.compareTo(calA);
            });
            break;
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Card de Meta Semanal
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: context.divider),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.track_changes_rounded,
                              color: AppColors.primaryLight,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'META DE CÁRDIO SEMANAL',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: context.onBackground,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '$totalMinutesThisWeek / $weeklyGoal min',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryLight,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: percent,
                        minHeight: 10,
                        backgroundColor: context.divider.withValues(alpha: 0.1),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.primaryLight,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$percentFormatted% concluído',
                          style: TextStyle(
                            fontSize: 11,
                            color: context.onSurface,
                          ),
                        ),
                        if (percent >= 1.0)
                          const Row(
                            children: [
                              Icon(
                                Icons.check_circle_rounded,
                                color: Colors.green,
                                size: 14,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Meta Atingida! 🎉',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Card de Evolução
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: context.divider),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.analytics_rounded,
                          color: AppColors.primaryLight,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'EVOLUÇÃO NAS ÚLTIMAS SEMANAS',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: context.onBackground,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    CardioProgressChart(cardios: cardios),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Histórico label
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                'HISTÓRICO DE SESSÕES',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: context.onSurface.withValues(alpha: 0.6),
                  letterSpacing: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Filter & Sort UI Dropdowns
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: context.divider.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: context.divider.withValues(alpha: 0.1),
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedTypeFilter,
                        isExpanded: true,
                        style: TextStyle(
                          fontSize: 12,
                          color: context.onBackground,
                        ),
                        icon: const Icon(Icons.filter_alt_rounded, size: 16),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedTypeFilter = val;
                            });
                          }
                        },
                        items:
                            [
                                  'Todos',
                                  'Esteira',
                                  'Bicicleta',
                                  'Escada',
                                  'Elíptico',
                                  'Corrida de Rua',
                                  'Outro',
                                ]
                                .map(
                                  (t) => DropdownMenuItem(
                                    value: t,
                                    child: Text(t),
                                  ),
                                )
                                .toList(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: context.divider.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: context.divider.withValues(alpha: 0.1),
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedSortOption,
                        isExpanded: true,
                        style: TextStyle(
                          fontSize: 12,
                          color: context.onBackground,
                        ),
                        icon: const Icon(Icons.sort_rounded, size: 16),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedSortOption = val;
                            });
                          }
                        },
                        items:
                            [
                                  'Data (Mais recente)',
                                  'Data (Mais antiga)',
                                  'Duração (Maior)',
                                  'Duração (Menor)',
                                  'Distância (Maior)',
                                  'Calorias (Maior)',
                                ]
                                .map(
                                  (o) => DropdownMenuItem(
                                    value: o,
                                    child: Text(o),
                                  ),
                                )
                                .toList(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (filteredAndSorted.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Text(
                    _selectedTypeFilter == 'Todos'
                        ? 'Nenhum treino de cárdio registrado ainda. 🏃'
                        : 'Nenhum treino de $_selectedTypeFilter registrado. 🏃',
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredAndSorted.length,
                itemBuilder: (context, index) {
                  final c = filteredAndSorted[index];
                  final date = DateTime.tryParse(c.data) ?? DateTime.now();
                  final minutes = c.duracaoSegundos ~/ 60;
                  final seconds = c.duracaoSegundos % 60;
                  final timeStr = minutes > 0
                      ? '${minutes}m ${seconds}s'
                      : '${seconds}s';

                  IconData typeIcon;
                  switch (c.tipo) {
                    case 'Esteira':
                    case 'Corrida de Rua':
                      typeIcon = Icons.directions_run_rounded;
                      break;
                    case 'Bicicleta':
                      typeIcon = Icons.pedal_bike_rounded;
                      break;
                    case 'Escada':
                      typeIcon = Icons.stairs_rounded;
                      break;
                    case 'Elíptico':
                      typeIcon = Icons.double_arrow_rounded;
                      break;
                    default:
                      typeIcon = Icons.sports_gymnastics_rounded;
                  }

                  Color intensityColor;
                  switch (c.intensidade) {
                    case 'Leve':
                      intensityColor = Colors.teal;
                      break;
                    case 'Alta':
                      intensityColor = Colors.red;
                      break;
                    default:
                      intensityColor = Colors.orange;
                  }

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: context.divider),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primaryLight.withValues(
                          alpha: 0.1,
                        ),
                        foregroundColor: AppColors.primaryLight,
                        child: Icon(typeIcon),
                      ),
                      title: Row(
                        children: [
                          Text(
                            c.tipo,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: intensityColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              c.intensidade ?? 'Moderada',
                              style: TextStyle(
                                fontSize: 10,
                                color: intensityColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text('Data: ${dateFormatter.format(date)}'),
                          const SizedBox(height: 2),
                          Wrap(
                            spacing: 12,
                            runSpacing: 4,
                            children: [
                              Text('Tempo: $timeStr'),
                              if (c.distanciaKm != null)
                                Text(
                                  'Distância: ${c.distanciaKm!.toStringAsFixed(2)} km',
                                ),
                              if (c.calorias != null)
                                Text('Calorias: ${c.calorias} kcal'),
                            ],
                          ),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          color: Colors.red,
                        ),
                        onPressed: () => _confirmDeleteCardio(context, c.id),
                      ),
                    ),
                  );
                },
              ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Erro ao carregar cardios: $err')),
    );
  }
}
