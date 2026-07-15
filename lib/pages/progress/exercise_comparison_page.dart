// lib/pages/progress/exercise_comparison_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import 'package:flutter/services.dart';

import '../../core/database/app_database.dart';
import '../../core/providers/providers.dart';
import '../../core/theme/app_theme.dart';

final exerciseLogsProvider = StreamProvider.family<List<ExerciseLog>, int>((ref, exerciseId) {
  return ref.watch(logDaoProvider).watchExerciseLogs(exerciseId);
});

class ExerciseComparisonPage extends ConsumerStatefulWidget {
  final int? initialExerciseId;
  final String? initialExerciseName;

  const ExerciseComparisonPage({
    super.key,
    this.initialExerciseId,
    this.initialExerciseName,
  });

  @override
  ConsumerState<ExerciseComparisonPage> createState() => _ExerciseComparisonPageState();
}

class _ExerciseComparisonPageState extends ConsumerState<ExerciseComparisonPage> {
  int? _selectedExerciseId;
  String? _selectedExerciseName;
  int _activeSegment = 0; // 0 = Tabela, 1 = Gráfico
  int _filterPeriod = 2; // 0 = 5 treinos, 1 = 10 treinos, 2 = tudo
  double _chartScale = 1.0;
  double _baseScale = 1.0;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedExerciseId = widget.initialExerciseId;
    _selectedExerciseName = widget.initialExerciseName;
    if (_selectedExerciseName != null) {
      _searchController.text = _selectedExerciseName!;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  double _calculate1RM(double weight, int reps) {
    if (weight <= 0) return 0.0;
    // Epley Formula
    return weight * (1 + reps / 30.0);
  }

  void _shareTableAsMarkdown(List<_ExerciseDayGroup> groups) {
    if (groups.isEmpty) return;

    final maxSets = groups.fold(0, (maxVal, g) => max(maxVal, g.logs.length));
    final buffer = StringBuffer();
    buffer.writeln('## Evolução: $_selectedExerciseName');
    buffer.writeln();
    
    // Header
    buffer.write('| Data |');
    for (int i = 1; i <= maxSets; i++) {
      buffer.write(' Série $i |');
    }
    buffer.writeln(' Carga Máx | Volume Total | Est. 1RM |');

    // Divider
    buffer.write('|---|');
    for (int i = 1; i <= maxSets; i++) {
      buffer.write('---|');
    }
    buffer.writeln('---|---|---|');

    // Rows
    final df = DateFormat('dd/MM/yyyy');
    for (final g in groups) {
      buffer.write('| ${df.format(g.date)} |');
      for (int i = 0; i < maxSets; i++) {
        if (i < g.logs.length) {
          final log = g.logs[i];
          buffer.write(' ${log.peso.toStringAsFixed(1)}kg x ${log.repeticoes} |');
        } else {
          buffer.write(' - |');
        }
      }
      final maxWeight = g.logs.map((l) => l.peso).fold(0.0, max);
      final totalVolume = g.logs.map((l) => l.peso * l.repeticoes).fold(0.0, (sum, val) => sum + val);
      final max1RM = g.logs.map((l) => _calculate1RM(l.peso, l.repeticoes)).fold(0.0, max);
      
      buffer.writeln(' ${maxWeight.toStringAsFixed(1)}kg | ${totalVolume.toStringAsFixed(1)}kg | ${max1RM.toStringAsFixed(1)}kg |');
    }

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tabela comparativa copiada em formato Markdown!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final exercisesAsync = ref.watch(allExercisesProvider);
    final isDark = context.isDark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Evolução do Exercício',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          if (_selectedExerciseId != null)
            IconButton(
              icon: const Icon(Icons.share_rounded),
              tooltip: 'Copiar Tabela',
              onPressed: () {
                // Copia o histórico atual
                final logsAsync = ref.read(exerciseLogsProvider(_selectedExerciseId!));
                logsAsync.whenData((logs) {
                  final groups = _groupLogs(logs);
                  _shareTableAsMarkdown(groups);
                });
              },
            ),
        ],
      ),
      body: exercisesAsync.when(
        data: (exercises) {
          // Garante que temos um exercício selecionado
          if (_selectedExerciseId == null && exercises.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              setState(() {
                _selectedExerciseId = exercises.first.id;
                _selectedExerciseName = exercises.first.nome;
                _searchController.text = exercises.first.nome;
              });
            });
          }

          return Column(
            children: [
              // Seletor de Exercício
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Autocomplete<Exercise>(
                  initialValue: TextEditingValue(text: _selectedExerciseName ?? ''),
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text.isEmpty) {
                      return exercises;
                    }
                    return exercises.where((option) => option.nome
                        .toLowerCase()
                        .contains(textEditingValue.text.toLowerCase()));
                  },
                  displayStringForOption: (option) => option.nome,
                  onSelected: (option) {
                    setState(() {
                      _selectedExerciseId = option.id;
                      _selectedExerciseName = option.nome;
                      _searchController.text = option.nome;
                    });
                  },
                  fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                    return TextField(
                      controller: controller,
                      focusNode: focusNode,
                      decoration: InputDecoration(
                        labelText: 'Pesquisar Exercício',
                        prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
                        suffixIcon: controller.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18),
                                onPressed: () {
                                  controller.clear();
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        filled: true,
                        fillColor: context.surfaceColor,
                      ),
                    );
                  },
                ),
              ),

              if (_selectedExerciseId != null) ...[
                // Segmented Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: SegmentedButton<int>(
                          segments: const [
                            ButtonSegment(
                              value: 0,
                              label: Text('Tabela'),
                              icon: Icon(Icons.table_chart_rounded, size: 18),
                            ),
                            ButtonSegment(
                              value: 1,
                              label: Text('Gráfico'),
                              icon: Icon(Icons.show_chart_rounded, size: 18),
                            ),
                          ],
                          selected: {_activeSegment},
                          onSelectionChanged: (val) {
                            setState(() {
                              _activeSegment = val.first;
                            });
                          },
                          style: SegmentedButton.styleFrom(
                            selectedBackgroundColor: AppColors.primary,
                            selectedForegroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Conteúdo
                Expanded(
                  child: Consumer(
                    builder: (context, ref, child) {
                      final logsAsync = ref.watch(exerciseLogsProvider(_selectedExerciseId!));
                      return logsAsync.when(
                        data: (logs) {
                          final groups = _groupLogs(logs);
                          if (groups.isEmpty) {
                            return _buildEmptyState();
                          }
                          return _activeSegment == 0
                              ? _buildTable(groups)
                              : _buildChart(groups, isDark);
                        },
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (err, _) => Center(
                          child: Text('Erro ao carregar dados: $err'),
                        ),
                      );
                    },
                  ),
                ),
              ] else
                const Expanded(
                  child: Center(
                    child: Text('Nenhum exercício selecionado.'),
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Erro ao carregar exercícios: $err')),
      ),
    );
  }

  List<_ExerciseDayGroup> _groupLogs(List<ExerciseLog> logs) {
    final Map<int, List<ExerciseLog>> groups = {};
    for (final log in logs) {
      groups.putIfAbsent(log.sessionId, () => []).add(log);
    }

    final List<_ExerciseDayGroup> list = groups.entries.map((e) {
      final sessionLogs = e.value;
      sessionLogs.sort((a, b) => a.serie.compareTo(b.serie));
      final date = DateTime.tryParse(sessionLogs.first.data) ?? DateTime.now();
      return _ExerciseDayGroup(
        sessionId: e.key,
        date: date,
        logs: sessionLogs,
      );
    }).toList();

    // Novo para antigo
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_rounded, size: 64, color: context.onSurface.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text(
            'Nenhum histórico encontrado',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: context.onBackground,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              'Realize este exercício em uma sessão de treino concluída para iniciar o comparativo.',
              style: TextStyle(
                fontSize: 13,
                color: context.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  String _getWeekdayName(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Segunda-feira';
      case DateTime.tuesday:
        return 'Terça-feira';
      case DateTime.wednesday:
        return 'Quarta-feira';
      case DateTime.thursday:
        return 'Quinta-feira';
      case DateTime.friday:
        return 'Sexta-feira';
      case DateTime.saturday:
        return 'Sábado';
      case DateTime.sunday:
        return 'Domingo';
      default:
        return '';
    }
  }

  Widget _buildTable(List<_ExerciseDayGroup> groups) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth <= 600) {
          return _buildMobileCards(groups);
        } else {
          return _buildDesktopTable(groups);
        }
      },
    );
  }

  Widget _buildMobileCards(List<_ExerciseDayGroup> groups) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: groups.length,
      itemBuilder: (context, index) {
        return _buildMobileCard(context, groups[index], index);
      },
    );
  }

  Widget _buildMobileCard(BuildContext context, _ExerciseDayGroup group, int index) {
    final maxWeight = group.logs.map((l) => l.peso).fold(0.0, max);
    final totalVolume = group.logs.map((l) => l.peso * l.repeticoes).fold(0.0, (sum, val) => sum + val);
    final max1RM = group.logs.map((l) => _calculate1RM(l.peso, l.repeticoes)).fold(0.0, max);
    final weekdayName = _getWeekdayName(group.date.weekday);
    final formattedDate = '$weekdayName, ${DateFormat('dd/MM/yyyy').format(group.date)}';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: context.divider.withValues(alpha: 0.15)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho: Data e Est. 1RM
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    formattedDate,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.emoji_events_rounded, size: 12, color: AppColors.success),
                      const SizedBox(width: 4),
                      Text(
                        '1RM: ${max1RM.toStringAsFixed(1)} kg',
                        style: const TextStyle(
                          color: AppColors.success,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 20),

            // Séries Realizadas (Chips compactos)
            const Text(
              'Séries realizadas:',
              style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: group.logs.map((log) {
                final isMax = log.peso == maxWeight && log.peso > 0;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isMax
                        ? AppColors.primary.withValues(alpha: 0.1)
                        : (context.isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02)),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isMax
                          ? AppColors.primaryLight.withValues(alpha: 0.4)
                          : context.divider.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Text(
                    '${log.serie}ª: ${log.peso > 0 ? "${log.peso.toStringAsFixed(1)}kg" : "PC"} x ${log.repeticoes}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isMax ? FontWeight.bold : FontWeight.normal,
                      color: isMax ? AppColors.primaryLight : context.onBackground,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Métricas rápidas de rodapé
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildMiniMetric(
                  icon: Icons.fitness_center_rounded,
                  color: AppColors.primaryLight,
                  label: 'Carga Máx',
                  value: maxWeight > 0 ? '${maxWeight.toStringAsFixed(1)} kg' : 'PC',
                ),
                _buildMiniMetric(
                  icon: Icons.flash_on_rounded,
                  color: Colors.orange,
                  label: 'Vol. Total',
                  value: totalVolume > 0 ? '${totalVolume.toStringAsFixed(1)} kg' : '-',
                ),
                _buildMiniMetric(
                  icon: Icons.tag,
                  color: Colors.teal,
                  label: 'Total Séries',
                  value: '${group.logs.length}',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniMetric({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopTable(List<_ExerciseDayGroup> groups) {
    final maxSets = groups.fold(0, (maxVal, g) => max(maxVal, g.logs.length));
    final df = DateFormat('dd/MM/yy');

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: context.divider.withValues(alpha: 0.3)),
        ),
        elevation: 0,
        borderOnForeground: true,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            horizontalMargin: 12,
            columnSpacing: 20,
            headingRowColor: WidgetStateProperty.all(
              context.isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02),
            ),
            columns: [
              const DataColumn(
                label: Text(
                  'Data',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
              ...List.generate(maxSets, (index) {
                return DataColumn(
                  label: Text(
                    'Série ${index + 1}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                );
              }),
              const DataColumn(
                label: Row(
                  children: [
                    Icon(Icons.fitness_center_rounded, size: 14, color: AppColors.primaryLight),
                    SizedBox(width: 4),
                    Text('Máx', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
              ),
              const DataColumn(
                label: Row(
                  children: [
                    Icon(Icons.flash_on_rounded, size: 14, color: Colors.orange),
                    SizedBox(width: 4),
                    Text('Volume', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
              ),
              const DataColumn(
                label: Row(
                  children: [
                    Icon(Icons.emoji_events_rounded, size: 14, color: Colors.yellow),
                    SizedBox(width: 4),
                    Text('Est. 1RM', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
              ),
            ],
            rows: List.generate(groups.length, (rowIdx) {
              final group = groups[rowIdx];
              final maxWeight = group.logs.map((l) => l.peso).fold(0.0, max);
              final totalVolume = group.logs.map((l) => l.peso * l.repeticoes).fold(0.0, (sum, val) => sum + val);
              final max1RM = group.logs.map((l) => _calculate1RM(l.peso, l.repeticoes)).fold(0.0, max);

              return DataRow(
                color: WidgetStateProperty.resolveWith<Color?>((states) {
                  if (rowIdx.isEven) return null;
                  return context.isDark ? Colors.white.withValues(alpha: 0.01) : Colors.black.withValues(alpha: 0.01);
                }),
                cells: [
                  // Data
                  DataCell(
                    Text(
                      df.format(group.date),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                  // Séries
                  ...List.generate(maxSets, (setIdx) {
                    if (setIdx < group.logs.length) {
                      final log = group.logs[setIdx];
                      final isMax = log.peso == maxWeight && log.peso > 0;
                      return DataCell(
                        Text(
                          log.peso > 0
                              ? '${log.peso.toStringAsFixed(1)} x ${log.repeticoes}'
                              : 'PC x ${log.repeticoes}',
                          style: TextStyle(
                            fontSize: 13,
                            color: isMax ? AppColors.primaryLight : context.onBackground,
                            fontWeight: isMax ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      );
                    }
                    return const DataCell(Text('-', style: TextStyle(color: Colors.grey, fontSize: 13)));
                  }),
                  // Máximo
                  DataCell(
                    Text(
                      maxWeight > 0 ? '${maxWeight.toStringAsFixed(1)} kg' : 'PC',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                  // Volume
                  DataCell(
                    Text(
                      totalVolume > 0 ? '${totalVolume.toStringAsFixed(1)} kg' : '-',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  // 1RM
                  DataCell(
                    Text(
                      max1RM > 0 ? '${max1RM.toStringAsFixed(1)} kg' : 'PC',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.success, fontSize: 13),
                    ),
                  ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildChart(List<_ExerciseDayGroup> groups, bool isDark) {
    // 1. Filtrar o período selecionado
    List<_ExerciseDayGroup> filteredGroups = groups;
    if (_filterPeriod == 0) {
      filteredGroups = groups.take(5).toList();
    } else if (_filterPeriod == 1) {
      filteredGroups = groups.take(10).toList();
    }

    // Para o gráfico, exibimos em ordem cronológica (antigo para novo)
    final chronList = List<_ExerciseDayGroup>.from(filteredGroups).reversed.toList();
    if (chronList.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Text(
            'Sem dados suficientes para este período.',
            style: TextStyle(color: context.onSurface.withValues(alpha: 0.6)),
          ),
        ),
      );
    }

    final maxWeightSpots = <FlSpot>[];
    final est1RMSpots = <FlSpot>[];

    for (int i = 0; i < chronList.length; i++) {
      final g = chronList[i];
      final maxWeight = g.logs.map((l) => l.peso).fold(0.0, max);
      final max1RM = g.logs.map((l) => _calculate1RM(l.peso, l.repeticoes)).fold(0.0, max);
      
      maxWeightSpots.add(FlSpot(i.toDouble(), maxWeight));
      est1RMSpots.add(FlSpot(i.toDouble(), max1RM));
    }

    final allY = [...maxWeightSpots, ...est1RMSpots].map((s) => s.y).toList();
    final minVal = allY.reduce((a, b) => a < b ? a : b);
    final maxVal = allY.reduce((a, b) => a > b ? a : b);
    
    final minY = minVal > 0 ? max(0.0, minVal * 0.85) : 0.0;
    final maxY = maxVal > 0 ? maxVal * 1.15 : 20.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Largura base do gráfico se ajusta ao número de pontos para não espremer
        final double baseWidth = max(constraints.maxWidth - 40, chronList.length * 60.0);
        final double chartWidth = baseWidth * _chartScale;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Filtros de Período & Zoom
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: List.generate(3, (index) {
                      final labels = ['5 Treinos', '10 Treinos', 'Tudo'];
                      final isSelected = _filterPeriod == index;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6.0),
                        child: ChoiceChip(
                          label: Text(
                            labels[index],
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? Colors.white : context.onSurface.withValues(alpha: 0.8),
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: AppColors.primary,
                          backgroundColor: context.isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
                          checkmarkColor: Colors.white,
                          showCheckmark: false,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _filterPeriod = index;
                                _chartScale = 1.0;
                              });
                            }
                          },
                        ),
                      );
                    }),
                  ),
                  if (_chartScale > 1.0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Zoom: ${_chartScale.toStringAsFixed(1)}x',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryLight,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Legenda
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLegendItem(AppColors.primary, 'Carga Máxima'),
                  const SizedBox(width: 24),
                  _buildLegendItem(AppColors.success, 'Est. 1RM'),
                ],
              ),
              const SizedBox(height: 16),
              
              // Gráfico com Zoom e Scroll
              Expanded(
                child: GestureDetector(
                  onScaleStart: (details) {
                    _baseScale = _chartScale;
                  },
                  onScaleUpdate: (details) {
                    setState(() {
                      _chartScale = (_baseScale * details.horizontalScale).clamp(1.0, 3.5);
                    });
                  },
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Container(
                      width: chartWidth,
                      padding: const EdgeInsets.fromLTRB(8, 16, 24, 8),
                      child: LineChart(
                        LineChartData(
                          minY: minY,
                          maxY: maxY,
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: true,
                            getDrawingHorizontalLine: (val) => FlLine(
                              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04),
                              strokeWidth: 1,
                            ),
                            getDrawingVerticalLine: (val) => FlLine(
                              color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02),
                              strokeWidth: 1,
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 40,
                                getTitlesWidget: (val, meta) {
                                  return Text(
                                    '${val.toInt()}kg',
                                    style: TextStyle(color: context.onSurface.withValues(alpha: 0.6), fontSize: 9),
                                  );
                                },
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 32,
                                getTitlesWidget: (val, meta) {
                                  final idx = val.toInt();
                                  if (idx < 0 || idx >= chronList.length) return const SizedBox.shrink();
                                  final d = chronList[idx].date;
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}',
                                      style: TextStyle(
                                        color: context.onSurface.withValues(alpha: 0.6),
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          ),
                          lineTouchData: LineTouchData(
                            getTouchedSpotIndicator: (LineChartBarData barData, List<int> spotIndexes) {
                              return spotIndexes.map((index) {
                                return TouchedSpotIndicatorData(
                                  FlLine(
                                    color: barData.color?.withValues(alpha: 0.25) ?? Colors.blue.withValues(alpha: 0.25),
                                    strokeWidth: 2,
                                    dashArray: [4, 4],
                                  ),
                                  FlDotData(
                                    show: true,
                                    getDotPainter: (spot, percent, barData, index) {
                                      return FlDotCirclePainter(
                                        radius: 6,
                                        color: barData.color ?? Colors.blue,
                                        strokeWidth: 2,
                                        strokeColor: Colors.white,
                                      );
                                    },
                                  ),
                                );
                              }).toList();
                            },
                            touchTooltipData: LineTouchTooltipData(
                              getTooltipColor: (touchedSpot) => context.surfaceColor,
                              getTooltipItems: (touchedSpots) {
                                return touchedSpots.map((spot) {
                                  final idx = spot.x.toInt();
                                  if (idx < 0 || idx >= chronList.length) return null;
                                  final is1RM = spot.barIndex == 1;
                                  final label = is1RM ? 'Est. 1RM' : 'Carga Máx';
                                  final color = is1RM ? AppColors.success : AppColors.primaryLight;
                                  return LineTooltipItem(
                                    '$label: ${spot.y.toStringAsFixed(1)} kg',
                                    TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11),
                                  );
                                }).toList();
                              },
                            ),
                          ),
                          lineBarsData: [
                            LineChartBarData(
                              spots: maxWeightSpots,
                              isCurved: true,
                              color: AppColors.primary,
                              barWidth: 3.5,
                              isStrokeCapRound: true,
                              dotData: const FlDotData(show: true),
                              belowBarData: BarAreaData(
                                show: true,
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    AppColors.primary.withValues(alpha: 0.25),
                                    AppColors.primary.withValues(alpha: 0.0),
                                  ],
                                ),
                              ),
                            ),
                            LineChartBarData(
                              spots: est1RMSpots,
                              isCurved: true,
                              color: AppColors.success,
                              barWidth: 3.5,
                              isStrokeCapRound: true,
                              dotData: const FlDotData(show: true),
                              belowBarData: BarAreaData(
                                show: true,
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    AppColors.success.withValues(alpha: 0.25),
                                    AppColors.success.withValues(alpha: 0.0),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              
              // Instruções de Uso
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.zoom_in_rounded, size: 12, color: context.onSurface.withValues(alpha: 0.5)),
                      const SizedBox(width: 6),
                      Text(
                        '💡 Use o movimento de pinça (zoom) e deslize horizontalmente',
                        style: TextStyle(
                          fontSize: 10,
                          fontStyle: FontStyle.italic,
                          color: context.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: context.onBackground,
          ),
        ),
      ],
    );
  }
}

class _ExerciseDayGroup {
  final int sessionId;
  final DateTime date;
  final List<ExerciseLog> logs;

  _ExerciseDayGroup({
    required this.sessionId,
    required this.date,
    required this.logs,
  });
}
