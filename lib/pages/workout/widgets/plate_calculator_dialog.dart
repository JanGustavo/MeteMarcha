import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/decimal_input_formatter.dart';

class PlateCalculatorDialog extends StatefulWidget {
  final double initialWeight;
  final ValueChanged<double> onApplyWeight;

  const PlateCalculatorDialog({
    super.key,
    required this.initialWeight,
    required this.onApplyWeight,
  });

  @override
  State<PlateCalculatorDialog> createState() => _PlateCalculatorDialogState();
}

class _PlateCalculatorDialogState extends State<PlateCalculatorDialog> {
  late double _totalWeight;
  double _barWeight = 20.0;
  final _weightCtrl = TextEditingController();

  final List<double> _barOptions = [20.0, 15.0, 10.0, 12.0, 8.0, 0.0];

  @override
  void initState() {
    super.initState();
    _totalWeight = widget.initialWeight;
    _weightCtrl.text = _totalWeight % 1 == 0
        ? _totalWeight.toInt().toString()
        : _totalWeight.toStringAsFixed(1);
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    super.dispose();
  }

  Map<double, int> _calculatePlates() {
    final double sideWeight = (_totalWeight - _barWeight) / 2.0;
    if (sideWeight <= 0) return {};

    final availablePlates = [25.0, 20.0, 15.0, 10.0, 5.0, 2.5, 2.0, 1.25, 1.0, 0.5];
    final Map<double, int> result = {};
    int remaining = (sideWeight * 100).round();

    for (final plate in availablePlates) {
      final plateInt = (plate * 100).round();
      if (remaining >= plateInt) {
        final count = remaining ~/ plateInt;
        result[plate] = count;
        remaining -= count * plateInt;
      }
    }
    return result;
  }

  Color _getPlateColor(double weight) {
    if (weight >= 25.0) return Colors.red[800]!;
    if (weight >= 20.0) return Colors.blue[800]!;
    if (weight >= 15.0) return Colors.yellow[800]!;
    if (weight >= 10.0) return Colors.green[800]!;
    if (weight >= 5.0) return Colors.white60;
    return Colors.grey[700]!;
  }

  @override
  Widget build(BuildContext context) {
    final plates = _calculatePlates();
    final sideWeight = (_totalWeight - _barWeight) / 2.0;

    return AlertDialog(
      backgroundColor: context.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          const Icon(Icons.calculate_rounded, color: AppColors.primaryLight),
          const SizedBox(width: 10),
          const Text(
            'Calculadora de Anilhas',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PESO TOTAL DESEJADO (kg)',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: context.onSurface, letterSpacing: 1.0),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _weightCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [DecimalInputFormatter()],
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 20),
                  onPressed: () {
                    _weightCtrl.clear();
                    setState(() => _totalWeight = 0.0);
                  },
                ),
              ),
              onChanged: (val) {
                setState(() {
                  _totalWeight = double.tryParse(val.replaceAll(',', '.')) ?? 0.0;
                });
              },
            ),
            const SizedBox(height: 16),

            Text(
              'PESO DA BARRA (kg)',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: context.onSurface, letterSpacing: 1.0),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _barOptions.map((opt) {
                  final isSelected = _barWeight == opt;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6.0),
                    child: ChoiceChip(
                      label: Text('${opt % 1 == 0 ? opt.toInt() : opt} kg'),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _barWeight = opt);
                        }
                      },
                      selectedColor: AppColors.primary,
                      backgroundColor: context.surfaceColor,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : context.onBackground,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),

            Divider(color: context.divider),
            const SizedBox(height: 12),

            if (sideWeight <= 0)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'Insira um peso maior que a barra.',
                    style: TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),
              )
            else ...[
              Center(
                child: Column(
                  children: [
                    Text(
                      'CADA LADO RECEBE',
                      style: TextStyle(fontSize: 10, color: context.onSurface.withOpacity(0.8), letterSpacing: 1.5),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${sideWeight % 1 == 0 ? sideWeight.toInt() : sideWeight.toStringAsFixed(2)} kg',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Colors.amber[400],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              Text(
                'ANILHAS POR LADO:',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: context.onSurface, letterSpacing: 1.0),
              ),
              const SizedBox(height: 8),
              if (plates.isEmpty)
                Text(
                  'Nenhuma anilha necessária (apenas a barra).',
                  style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: context.onSurface),
                )
              else
                Column(
                  children: plates.entries.map((entry) {
                    final weight = entry.key;
                    final count = entry.value;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: _getPlateColor(weight),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.black38, width: 1),
                              boxShadow: const [
                                BoxShadow(color: Colors.black26, blurRadius: 2, offset: Offset(0, 1))
                              ]
                            ),
                            child: Center(
                              child: Text(
                                '${weight % 1 == 0 ? weight.toInt() : weight}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '${weight % 1 == 0 ? weight.toInt() : weight} kg',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          Text(
                            'x $count ${count == 1 ? "anilha" : "anilhas"}',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primaryLight),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Fechar'),
        ),
        if (sideWeight > 0)
          ElevatedButton(
            onPressed: () {
              widget.onApplyWeight(_totalWeight);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Aplicar Peso'),
          ),
      ],
    );
  }
}
