import '../../../core/media/photo_capture.dart';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:gym_tracker/core/database/app_database.dart';
import 'package:gym_tracker/core/theme/app_theme.dart';
import 'package:gym_tracker/core/utils/decimal_input_formatter.dart';
import 'package:gym_tracker/pages/progress/widgets/progress_chart_components.dart';

class AddEditMeasurementSheet extends StatefulWidget {
  final BodyMeasurement? measurement;
  final double? userHeight;
  final Function(BodyMeasurementsCompanion entry) onSave;

  const AddEditMeasurementSheet({
    super.key,
    this.measurement,
    this.userHeight,
    required this.onSave,
  });

  @override
  State<AddEditMeasurementSheet> createState() =>
      _AddEditMeasurementSheetState();
}

class _AddEditMeasurementSheetState extends State<AddEditMeasurementSheet> {
  final _formKey = GlobalKey<FormState>();
  late DateTime _selectedDate;

  final _pesoCtrl = TextEditingController();
  final _gorduraCtrl = TextEditingController();
  final _massaMagraCtrl = TextEditingController();
  final _peitoCtrl = TextEditingController();
  final _cinturaCtrl = TextEditingController();
  final _bracoECtrl = TextEditingController();
  final _bracoDCtrl = TextEditingController();
  final _coxaECtrl = TextEditingController();
  final _coxaDCtrl = TextEditingController();
  final _panturrilhaECtrl = TextEditingController();
  final _panturrilhaDCtrl = TextEditingController();

  File? _selectedImage;
  String? _existingPhotoPath;

  @override
  void initState() {
    super.initState();
    final m = widget.measurement;
    _selectedDate = m != null
        ? DateTime.tryParse(m.data) ?? DateTime.now()
        : DateTime.now();

    if (m != null) {
      _pesoCtrl.text = m.peso?.toString() ?? '';
      _gorduraCtrl.text = m.gorduraPercentual?.toString() ?? '';
      _massaMagraCtrl.text = m.massaMagra?.toString() ?? '';
      _peitoCtrl.text = m.peito?.toString() ?? '';
      _cinturaCtrl.text = m.cintura?.toString() ?? '';
      _bracoECtrl.text = m.bracoEsquerdo?.toString() ?? '';
      _bracoDCtrl.text = m.bracoDireito?.toString() ?? '';
      _coxaECtrl.text = m.coxaEsquerda?.toString() ?? '';
      _coxaDCtrl.text = m.coxaDireita?.toString() ?? '';
      _panturrilhaECtrl.text = m.panturrilhaEsquerda?.toString() ?? '';
      _panturrilhaDCtrl.text = m.panturrilhaDireita?.toString() ?? '';
      _existingPhotoPath = m.fotoPath;
    }
  }

  @override
  void dispose() {
    _pesoCtrl.dispose();
    _gorduraCtrl.dispose();
    _massaMagraCtrl.dispose();
    _peitoCtrl.dispose();
    _cinturaCtrl.dispose();
    _bracoECtrl.dispose();
    _bracoDCtrl.dispose();
    _coxaECtrl.dispose();
    _coxaDCtrl.dispose();
    _panturrilhaECtrl.dispose();
    _panturrilhaDCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await pickAppPhoto(context, source: source);
      if (picked != null) {
        setState(() {
          _selectedImage = File(picked.path);
          _existingPhotoPath = null;
        });
      }
    } catch (_) {}
  }

  void _removePhoto() {
    setState(() {
      _selectedImage = null;
      _existingPhotoPath = null;
    });
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final peso = double.tryParse(_pesoCtrl.text);
    final gordura = double.tryParse(_gorduraCtrl.text);
    final massaMagra = double.tryParse(_massaMagraCtrl.text);
    final peito = double.tryParse(_peitoCtrl.text);
    final cintura = double.tryParse(_cinturaCtrl.text);
    final bracoE = double.tryParse(_bracoECtrl.text);
    final bracoD = double.tryParse(_bracoDCtrl.text);
    final coxaE = double.tryParse(_coxaECtrl.text);
    final coxaD = double.tryParse(_coxaDCtrl.text);
    final panturrilhaE = double.tryParse(_panturrilhaECtrl.text);
    final panturrilhaD = double.tryParse(_panturrilhaDCtrl.text);

    if (peso == null &&
        gordura == null &&
        massaMagra == null &&
        peito == null &&
        cintura == null &&
        bracoE == null &&
        bracoD == null &&
        coxaE == null &&
        coxaD == null &&
        panturrilhaE == null &&
        panturrilhaD == null &&
        _selectedImage == null &&
        _existingPhotoPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preencha pelo menos um campo ou adicione uma foto!'),
        ),
      );
      return;
    }

    String? fotoPath = _existingPhotoPath;
    if (_selectedImage != null) {
      final appDir = await getApplicationDocumentsDirectory();
      final photosDir = Directory('${appDir.path}/progress_photos');
      if (!await photosDir.exists()) {
        await photosDir.create(recursive: true);
      }
      final fileName = 'photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedFile = await _selectedImage!.copy(
        '${photosDir.path}/$fileName',
      );
      fotoPath = savedFile.path;
    }

    double? imc;
    if (peso != null && widget.userHeight != null && widget.userHeight! > 0) {
      final hM = widget.userHeight! / 100;
      imc = peso / (hM * hM);
    }

    final dateStr = _selectedDate.toIso8601String().split('T')[0];

    final entry = BodyMeasurementsCompanion(
      id: widget.measurement != null
          ? Value(widget.measurement!.id)
          : const Value.absent(),
      data: Value(dateStr),
      peso: Value(peso),
      gorduraPercentual: Value(gordura),
      massaMagra: Value(massaMagra),
      imc: Value(imc),
      peito: Value(peito),
      cintura: Value(cintura),
      bracoEsquerdo: Value(bracoE),
      bracoDireito: Value(bracoD),
      coxaEsquerda: Value(coxaE),
      coxaDireita: Value(coxaD),
      panturrilhaEsquerda: Value(panturrilhaE),
      panturrilhaDireita: Value(panturrilhaD),
      fotoPath: Value(fotoPath),
    );

    widget.onSave(entry);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Form(
      key: _formKey,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.measurement == null ? 'Nova Medida' : 'Editar Medida',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(
                  Icons.calendar_today_rounded,
                  color: AppColors.primaryLight,
                ),
                title: const Text(
                  'Data do Registro',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                subtitle: Text(
                  DateFormat('dd/MM/yyyy').format(_selectedDate),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                trailing: const Icon(Icons.arrow_drop_down_rounded),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setState(() {
                      _selectedDate = picked;
                    });
                  }
                },
              ),
            ),
            const SizedBox(height: 16),
            const ProgressSectionLabel('COMPOSIÇÃO CORPORAL'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _pesoCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [DecimalInputFormatter()],
                    decoration: const InputDecoration(
                      labelText: 'Peso (kg)',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    validator: (val) {
                      if (val != null &&
                          val.isNotEmpty &&
                          double.tryParse(val) == null) {
                        return 'Inválido';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _gorduraCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [DecimalInputFormatter()],
                    decoration: const InputDecoration(
                      labelText: 'Gordura (%)',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    validator: (val) {
                      if (val != null &&
                          val.isNotEmpty &&
                          double.tryParse(val) == null) {
                        return 'Inválido';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _massaMagraCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [DecimalInputFormatter()],
                    decoration: const InputDecoration(
                      labelText: 'Massa M. (kg)',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    validator: (val) {
                      if (val != null &&
                          val.isNotEmpty &&
                          double.tryParse(val) == null) {
                        return 'Inválido';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const ProgressSectionLabel('CIRCUNFERÊNCIAS (cm)'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildMeasurementField(_peitoCtrl, 'Peito')),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMeasurementField(_cinturaCtrl, 'Cintura'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMeasurementField(_bracoDCtrl, 'Braço Direito'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMeasurementField(_bracoECtrl, 'Braço Esquerdo'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMeasurementField(_coxaDCtrl, 'Coxa Direita'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMeasurementField(_coxaECtrl, 'Coxa Esquerda'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMeasurementField(
                    _panturrilhaDCtrl,
                    'Panturrilha Dir.',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMeasurementField(
                    _panturrilhaECtrl,
                    'Panturrilha Esq.',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const ProgressSectionLabel('FOTO DE PROGRESSO'),
            const SizedBox(height: 12),
            _buildPhotoPickerSection(isDark),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _submit,
                    child: const Text('Salvar'),
                  ),
                ),
              ],
            ),
            SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
          ],
        ),
      ),
    );
  }

  Widget _buildMeasurementField(
    TextEditingController controller,
    String label,
  ) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [DecimalInputFormatter()],
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
      ),
      validator: (val) {
        if (val != null && val.isNotEmpty && double.tryParse(val) == null) {
          return 'Inválido';
        }
        return null;
      },
    );
  }

  Widget _buildPhotoPickerSection(bool isDark) {
    final hasPhoto = _selectedImage != null || _existingPhotoPath != null;

    if (hasPhoto) {
      return Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: _selectedImage != null
                  ? Image.file(
                      _selectedImage!,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                    )
                  : Image.file(
                      File(_existingPhotoPath!),
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.broken_image, size: 48),
                    ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton.filled(
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.white,
                ),
                onPressed: _removePhoto,
                style: IconButton.styleFrom(backgroundColor: Colors.black54),
              ),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          builder: (ctx) => SafeArea(
            child: Wrap(
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_camera_rounded),
                  title: const Text('Câmera'),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _pickImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_rounded),
                  title: const Text('Galeria'),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _pickImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
      child: Container(
        height: 120,
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.grey.withValues(alpha: 0.3),
            style: BorderStyle.solid,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_a_photo_outlined,
              size: 32,
              color: isDark ? Colors.white60 : Colors.black45,
            ),
            const SizedBox(height: 8),
            Text(
              'Tirar ou escolher foto de progresso',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Fullscreen Image Viewer ──────────────────────────────────────────────────
