import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_tracker/core/database/app_database.dart';
import 'package:gym_tracker/core/providers/providers.dart';
import 'package:gym_tracker/core/theme/app_theme.dart';
import 'package:gym_tracker/core/services/health_connect_service.dart';
import 'package:gym_tracker/pages/progress/widgets/progress_chart_components.dart';
import 'package:gym_tracker/pages/progress/widgets/metric_summary_card.dart';
import 'package:gym_tracker/pages/progress/widgets/measurements_chart.dart';
import 'package:gym_tracker/pages/progress/widgets/measurement_card.dart';
import 'package:gym_tracker/pages/progress/widgets/add_edit_measurement_sheet.dart';

class BodyMeasurementsTab extends ConsumerStatefulWidget {
  const BodyMeasurementsTab({super.key});

  @override
  ConsumerState<BodyMeasurementsTab> createState() =>
      _BodyMeasurementsTabState();
}

class _BodyMeasurementsTabState extends ConsumerState<BodyMeasurementsTab> {
  String _selectedChartMetric = 'Peso';

  void _showAddEditMeasurementSheet([BodyMeasurement? measurement]) {
    final profile = ref.read(profileProvider).value;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              AddEditMeasurementSheet(
                measurement: measurement,
                userHeight: profile?.altura,
                onSave: (entry) async {
                  final dao = ref.read(profileDaoProvider);
                  if (measurement != null) {
                    final toUpdate = BodyMeasurement(
                      id: measurement.id,
                      data: entry.data.value,
                      peso: entry.peso.value,
                      gorduraPercentual: entry.gorduraPercentual.value,
                      massaMagra: entry.massaMagra.value,
                      imc: entry.imc.value,
                      peito: entry.peito.value,
                      cintura: entry.cintura.value,
                      bracoEsquerdo: entry.bracoEsquerdo.value,
                      bracoDireito: entry.bracoDireito.value,
                      coxaEsquerda: entry.coxaEsquerda.value,
                      coxaDireita: entry.coxaDireita.value,
                      panturrilhaEsquerda: entry.panturrilhaEsquerda.value,
                      panturrilhaDireita: entry.panturrilhaDireita.value,
                      fotoPath: entry.fotoPath.value,
                    );
                    await dao.updateMeasurement(toUpdate);

                    if (toUpdate.peso != null) {
                      final date =
                          DateTime.tryParse(toUpdate.data) ?? DateTime.now();
                      await HealthConnectService.instance.syncBodyMeasurement(
                        weightKg: toUpdate.peso!,
                        bodyFatPercent: toUpdate.gorduraPercentual,
                        bmi: toUpdate.imc,
                        dateTime: date,
                      );
                    }
                  } else {
                    await dao.insertMeasurement(entry);

                    if (entry.peso.value != null) {
                      final date =
                          DateTime.tryParse(entry.data.value) ?? DateTime.now();
                      await HealthConnectService.instance.syncBodyMeasurement(
                        weightKg: entry.peso.value!,
                        bodyFatPercent: entry.gorduraPercentual.value,
                        bmi: entry.imc.value,
                        dateTime: date,
                      );
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _deleteMeasurement(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir Registro?'),
        content: const Text(
          'Tem certeza que deseja apagar este registro de medidas? Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            child: const Text('Cancelar'),
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          TextButton(
            child: const Text(
              'Excluir',
              style: TextStyle(color: AppColors.primary),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final dao = ref.read(profileDaoProvider);
      await dao.deleteMeasurement(id);
    }
  }

  Widget _buildMetricSelector() {
    final metrics = [
      'Peso',
      'Gordura %',
      'Massa Magra',
      'IMC',
      'Peito',
      'Cintura',
      'Braço D.',
      'Braço E.',
      'Coxa D.',
      'Coxa E.',
      'Panturrilha D.',
      'Panturrilha E.',
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: metrics.map((m) {
          final isSelected = _selectedChartMetric == m;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(m),
              selected: isSelected,
              onSelected: (val) {
                if (val) {
                  setState(() {
                    _selectedChartMetric = m;
                  });
                }
              },
              selectedColor: AppColors.primary.withValues(alpha: 0.2),
              checkmarkColor: AppColors.primaryLight,
              labelStyle: TextStyle(
                color: isSelected ? AppColors.primaryLight : null,
                fontWeight: isSelected ? FontWeight.bold : null,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final measurementsAsync = ref.watch(bodyMeasurementsProvider);

    return measurementsAsync.when(
      data: (measurements) {
        if (measurements.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.straighten_rounded,
                    size: 64,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? context.onSurface.withValues(alpha: 0.5)
                        : AppColors.lightOnSurface.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Nenhum registro de medidas ainda',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Acompanhe seu peso, percentual de gordura, medidas corporais e tire fotos de progresso.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _showAddEditMeasurementSheet(),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Registrar Medidas'),
                  ),
                ],
              ),
            ),
          );
        }

        final latest = measurements.first;
        final prev = measurements.length > 1 ? measurements[1] : null;

        // Calculate trends
        final weightDiff = (latest.peso != null && prev?.peso != null)
            ? latest.peso! - prev!.peso!
            : 0.0;
        final fatDiff =
            (latest.gorduraPercentual != null &&
                prev?.gorduraPercentual != null)
            ? latest.gorduraPercentual! - prev!.gorduraPercentual!
            : 0.0;
        final leanDiff = (latest.massaMagra != null && prev?.massaMagra != null)
            ? latest.massaMagra! - prev!.massaMagra!
            : 0.0;
        final imcDiff = (latest.imc != null && prev?.imc != null)
            ? latest.imc! - prev!.imc!
            : 0.0;

        return ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            // Core stats dashboard
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: GridView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.45,
                ),
                children: [
                  MetricSummaryCard(
                    title: 'PESO',
                    value: latest.peso != null
                        ? '${latest.peso!.toStringAsFixed(1)} kg'
                        : 'N/A',
                    change: latest.peso != null && prev?.peso != null
                        ? '${weightDiff > 0 ? "+" : ""}${weightDiff.toStringAsFixed(1)} kg'
                        : '',
                    isPositiveChange: weightDiff >= 0,
                    icon: Icons.monitor_weight_outlined,
                    color: AppColors.info,
                  ),
                  MetricSummaryCard(
                    title: 'GORDURA',
                    value: latest.gorduraPercentual != null
                        ? '${latest.gorduraPercentual!.toStringAsFixed(1)}%'
                        : 'N/A',
                    change:
                        latest.gorduraPercentual != null &&
                            prev?.gorduraPercentual != null
                        ? '${fatDiff > 0 ? "+" : ""}${fatDiff.toStringAsFixed(1)}%'
                        : '',
                    isPositiveChange: fatDiff <= 0,
                    icon: Icons.percent_rounded,
                    color: AppColors.warning,
                  ),
                  MetricSummaryCard(
                    title: 'MASSA MAGRA',
                    value: latest.massaMagra != null
                        ? '${latest.massaMagra!.toStringAsFixed(1)} kg'
                        : 'N/A',
                    change:
                        latest.massaMagra != null && prev?.massaMagra != null
                        ? '${leanDiff > 0 ? "+" : ""}${leanDiff.toStringAsFixed(1)} kg'
                        : '',
                    isPositiveChange: leanDiff >= 0,
                    icon: Icons.fitness_center_rounded,
                    color: AppColors.success,
                  ),
                  MetricSummaryCard(
                    title: 'IMC',
                    value: latest.imc != null
                        ? latest.imc!.toStringAsFixed(1)
                        : 'N/A',
                    change: latest.imc != null && prev?.imc != null
                        ? '${imcDiff > 0 ? "+" : ""}${imcDiff.toStringAsFixed(1)}'
                        : '',
                    isPositiveChange: imcDiff <= 0,
                    icon: Icons.calculate_outlined,
                    color: AppColors.primaryLight,
                  ),
                ],
              ),
            ),

            // Evolution Chart Card
            Card(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: ProgressSectionLabel('EVOLUÇÃO HISTÓRICA'),
                    ),
                    const SizedBox(height: 12),
                    _buildMetricSelector(),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: MeasurementsChart(
                        measurements: measurements,
                        metric: _selectedChartMetric,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // History Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const ProgressSectionLabel('HISTÓRICO'),
                  IconButton.filledTonal(
                    onPressed: () => _showAddEditMeasurementSheet(),
                    icon: const Icon(Icons.add_rounded),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      foregroundColor: AppColors.primaryLight,
                    ),
                  ),
                ],
              ),
            ),

            // History List
            ...measurements.asMap().entries.map((entry) {
              final idx = entry.key;
              final item = entry.value;
              final itemPrev = idx + 1 < measurements.length
                  ? measurements[idx + 1]
                  : null;
              return MeasurementCard(
                measurement: item,
                previous: itemPrev,
                onEdit: () => _showAddEditMeasurementSheet(item),
                onDelete: () => _deleteMeasurement(item.id),
              );
            }),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, __) => Center(child: Text('Erro ao carregar medidas: $e')),
    );
  }
}

// ── Metric Summary Card ──────────────────────────────────────────────────────
