import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:gym_tracker/core/database/app_database.dart';
import 'package:gym_tracker/core/theme/app_theme.dart';
import 'package:gym_tracker/core/utils/premium_page_route.dart';
import 'package:gym_tracker/pages/progress/widgets/fullscreen_image_viewer.dart';

class MeasurementCard extends StatefulWidget {
  final BodyMeasurement measurement;
  final BodyMeasurement? previous;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const MeasurementCard({
    super.key,
    required this.measurement,
    this.previous,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<MeasurementCard> createState() => _MeasurementCardState();
}

class _MeasurementCardState extends State<MeasurementCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final m = widget.measurement;
    final prev = widget.previous;
    final date = DateTime.tryParse(m.data) ?? DateTime.now();
    final dateStr = DateFormat('dd/MM/yyyy').format(date);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        children: [
          ListTile(
            onTap: () {
              setState(() {
                _expanded = !_expanded;
              });
            },
            title: Row(
              children: [
                const Icon(
                  Icons.calendar_today_rounded,
                  size: 16,
                  color: AppColors.primaryLight,
                ),
                const SizedBox(width: 8),
                Text(
                  dateStr,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  if (m.peso != null)
                    _buildMiniBadge(
                      'Peso',
                      '${m.peso!.toStringAsFixed(1)} kg',
                      prev?.peso,
                      isWeight: true,
                    ),
                  if (m.gorduraPercentual != null)
                    _buildMiniBadge(
                      'Gordura',
                      '${m.gorduraPercentual!.toStringAsFixed(1)}%',
                      prev?.gorduraPercentual,
                      isFat: true,
                    ),
                  if (m.massaMagra != null)
                    _buildMiniBadge(
                      'Massa M.',
                      '${m.massaMagra!.toStringAsFixed(1)} kg',
                      prev?.massaMagra,
                      isLeanMass: true,
                    ),
                  if (m.imc != null)
                    _buildMiniBadge(
                      'IMC',
                      m.imc!.toStringAsFixed(1),
                      prev?.imc,
                    ),
                ],
              ),
            ),
            trailing: Icon(
              _expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
              color: context.onSurface,
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 1, indent: 16, endIndent: 16),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_hasAnyCircumference(m)) ...[
                    const Text(
                      'Medidas de Circunferência',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GridView(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 8,
                            childAspectRatio: 3.5,
                          ),
                      children: [
                        if (m.peito != null)
                          _buildCircumferenceTile(
                            'Peito',
                            m.peito!,
                            prev?.peito,
                          ),
                        if (m.cintura != null)
                          _buildCircumferenceTile(
                            'Cintura',
                            m.cintura!,
                            prev?.cintura,
                            lowerIsBetter: true,
                          ),
                        if (m.bracoDireito != null)
                          _buildCircumferenceTile(
                            'Braço D.',
                            m.bracoDireito!,
                            prev?.bracoDireito,
                          ),
                        if (m.bracoEsquerdo != null)
                          _buildCircumferenceTile(
                            'Braço E.',
                            m.bracoEsquerdo!,
                            prev?.bracoEsquerdo,
                          ),
                        if (m.coxaDireita != null)
                          _buildCircumferenceTile(
                            'Coxa D.',
                            m.coxaDireita!,
                            prev?.coxaDireita,
                          ),
                        if (m.coxaEsquerda != null)
                          _buildCircumferenceTile(
                            'Coxa E.',
                            m.coxaEsquerda!,
                            prev?.coxaEsquerda,
                          ),
                        if (m.panturrilhaDireita != null)
                          _buildCircumferenceTile(
                            'Panturrilha D.',
                            m.panturrilhaDireita!,
                            prev?.panturrilhaDireita,
                          ),
                        if (m.panturrilhaEsquerda != null)
                          _buildCircumferenceTile(
                            'Panturrilha E.',
                            m.panturrilhaEsquerda!,
                            prev?.panturrilhaEsquerda,
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (m.fotoPath != null) ...[
                    const Text(
                      'Foto de Progresso',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          PremiumPageRoute(
                            page: FullscreenImageViewer(
                              imagePath: m.fotoPath!,
                              dateStr: dateStr,
                            ),
                            transitionType: TransitionType.fade,
                          ),
                        );
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          height: 200,
                          width: double.infinity,
                          color: isDark
                              ? context.surfaceColor
                              : AppColors.lightSurface,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Image.file(
                                File(m.fotoPath!),
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.broken_image_rounded,
                                        size: 48,
                                        color: Colors.grey,
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'Imagem não encontrada',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                              Positioned(
                                bottom: 8,
                                right: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.6),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.zoom_in_rounded,
                                        size: 14,
                                        color: Colors.white,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'Toque para ampliar',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        icon: const Icon(Icons.edit_rounded, size: 16),
                        label: const Text(
                          'Editar',
                          style: TextStyle(fontSize: 12),
                        ),
                        onPressed: widget.onEdit,
                        style: TextButton.styleFrom(
                          foregroundColor: isDark
                              ? context.onBackground
                              : AppColors.lightOnBackground,
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          size: 16,
                        ),
                        label: const Text(
                          'Excluir',
                          style: TextStyle(fontSize: 12),
                        ),
                        onPressed: widget.onDelete,
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  bool _hasAnyCircumference(BodyMeasurement m) {
    return m.peito != null ||
        m.cintura != null ||
        m.bracoEsquerdo != null ||
        m.bracoDireito != null ||
        m.coxaEsquerda != null ||
        m.coxaDireita != null ||
        m.panturrilhaEsquerda != null ||
        m.panturrilhaDireita != null;
  }

  Widget _buildMiniBadge(
    String label,
    String value,
    double? prevVal, {
    bool isWeight = false,
    bool isFat = false,
    bool isLeanMass = false,
  }) {
    Color? diffColor;
    String diffText = '';

    if (prevVal != null) {
      final currentVal = double.tryParse(
        value.replaceAll(RegExp(r'[^0-9.]'), ''),
      );
      if (currentVal != null) {
        final diff = currentVal - prevVal;
        if (diff != 0) {
          final sign = diff > 0 ? '+' : '';
          diffText = ' ($sign${diff.toStringAsFixed(1)})';

          if (isFat) {
            diffColor = diff < 0 ? AppColors.success : AppColors.primary;
          } else if (isWeight || isLeanMass) {
            diffColor = diff > 0 ? AppColors.success : AppColors.primary;
          }
        }
      }
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: TextStyle(
                fontSize: 11,
                color: isDark ? context.onSurface : AppColors.lightOnSurface,
              ),
            ),
            TextSpan(
              text: value,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? context.onBackground
                    : AppColors.lightOnBackground,
              ),
            ),
            if (diffText.isNotEmpty)
              TextSpan(
                text: diffText,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: diffColor,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircumferenceTile(
    String label,
    double val,
    double? prevVal, {
    bool lowerIsBetter = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String diffText = '';
    Color? diffColor;

    if (prevVal != null) {
      final diff = val - prevVal;
      if (diff != 0) {
        final sign = diff > 0 ? '+' : '';
        diffText = ' $sign${diff.toStringAsFixed(1)} cm';
        if (lowerIsBetter) {
          diffColor = diff < 0 ? AppColors.success : AppColors.primary;
        } else {
          diffColor = diff > 0 ? AppColors.success : AppColors.primary;
        }
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.03)
            : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isDark ? context.onSurface : AppColors.lightOnSurface,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Text(
                '${val.toStringAsFixed(1)} cm',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? context.onBackground
                      : AppColors.lightOnBackground,
                ),
              ),
              if (diffText.isNotEmpty) ...[
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    diffText,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: diffColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ── Add/Edit Measurement Bottom Sheet ────────────────────────────────────────
