// lib/pages/profile/profile_page.dart

import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/services/health_connect_service.dart';

import '../../core/database/database_helper.dart'
    if (dart.library.js_interop) '../../core/database/database_helper_web.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../core/database/app_database.dart';
import '../../core/providers/providers.dart';
import '../../core/providers/progress_extended_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/week_utils.dart';
import '../../core/utils/decimal_input_formatter.dart';
import '../../core/utils/string_input_formatter.dart';
import '../../core/widgets/streak_badge.dart';
import '../../core/services/ota_update_service.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final _nomeCtrl = TextEditingController();
  final _alturaCtrl = TextEditingController();
  final _pesoCtrl = TextEditingController();

  bool _saving = false;
  bool _populated = false;
  bool _healthConnectEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadHealthConnectStatus();
  }

  void _loadHealthConnectStatus() async {
    final enabled = await HealthConnectService.instance.isEnabled();
    if (mounted) {
      setState(() {
        _healthConnectEnabled = enabled;
      });
    }
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _alturaCtrl.dispose();
    _pesoCtrl.dispose();
    super.dispose();
  }

  void _populate(UserProfile? p) {
    if (_populated || p == null) return;
    _nomeCtrl.text = p.nome ?? '';
    _alturaCtrl.text = p.altura != null ? p.altura!.toStringAsFixed(0) : '';
    _pesoCtrl.text = p.pesoAtual != null ? p.pesoAtual!.toStringAsFixed(1) : '';
    _populated = true;
  }

  Future<void> _save() async {
    setState(() => _saving = true);

    final peso = double.tryParse(_pesoCtrl.text.replaceAll(',', '.'));
    final altura = double.tryParse(_alturaCtrl.text);

    await ref.read(profileDaoProvider).upsertProfile(
          UserProfilesCompanion(
            nome: Value(_nomeCtrl.text.trim()),
            pesoAtual: Value(peso),
            altura: Value(altura),
          ),
        );

    // Salva também o peso desta semana
    if (peso != null) {
      await ref.read(profileDaoProvider).upsertWeeklyWeight(
            WeekUtils.currentWeekKey(),
            peso,
          );

      // Sincroniza com o Health Connect se estiver ativado
      if (_healthConnectEnabled) {
        await HealthConnectService.instance.syncBodyMeasurement(
          weightKg: peso,
          dateTime: DateTime.now(),
        );
      }
    }

    setState(() => _saving = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil atualizado ✓')),
      );
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      String finalPath;
      if (kIsWeb) {
        finalPath = pickedFile.path;
      } else {
        final appDir = await getApplicationDocumentsDirectory();
        final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final savedFile = await File(pickedFile.path).copy('${appDir.path}/$fileName');
        finalPath = savedFile.path;
      }

      await ref.read(profilePhotoProvider.notifier).setPhoto(finalPath);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao escolher imagem: $e')),
        );
      }
    }
  }

  void _showPhotoOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Foto de Perfil',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: context.onBackground,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: AppColors.primaryLight),
              title: const Text('Escolher da Galeria'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded, color: AppColors.primaryLight),
              title: const Text('Tirar Foto (Câmera)'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.link_rounded, color: AppColors.primaryLight),
              title: const Text('Usar GitHub ou Link URL'),
              onTap: () {
                Navigator.pop(ctx);
                _showUrlInputDialog(context);
              },
            ),
            if (ref.watch(profilePhotoProvider) != null)
              ListTile(
                leading: const Icon(Icons.delete_rounded, color: Colors.redAccent),
                title: const Text('Remover Foto', style: TextStyle(color: Colors.redAccent)),
                onTap: () async {
                  Navigator.pop(ctx);
                  await ref.read(profilePhotoProvider.notifier).setPhoto(null);
                },
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _showUrlInputDialog(BuildContext context) {
    final urlCtrl = TextEditingController(
        text: ref.read(profilePhotoProvider)?.startsWith('http') == true
            ? ref.read(profilePhotoProvider)
            : '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Foto do GitHub ou URL'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Insira seu usuário do GitHub (ex: JanGustavo) ou qualquer link de imagem da internet:',
              style: TextStyle(fontSize: 13, color: context.onSurface),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: urlCtrl,
              decoration: const InputDecoration(
                hintText: 'Nome de usuário ou Link URL',
                filled: true,
                prefixIcon: Icon(Icons.link_rounded),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              String input = urlCtrl.text.trim();
              if (input.isEmpty) return;

              String finalUrl = input;
              if (!input.startsWith('http://') && !input.startsWith('https://')) {
                finalUrl = 'https://github.com/$input.png';
              }

              Navigator.pop(ctx);
              await ref.read(profilePhotoProvider.notifier).setPhoto(finalUrl);
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportBackup(BuildContext context) async {
    try {
      final dbFolder = await getApplicationDocumentsDirectory();
      final dbFile = File('${dbFolder.path}/gym_tracker.sqlite');

      if (!await dbFile.exists()) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Nenhum dado encontrado para exportar!')),
          );
        }
        return;
      }

      final now = DateTime.now();
      final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final tempDir = await getTemporaryDirectory();
      final backupFile = await dbFile.copy('${tempDir.path}/metemacha_backup_$dateStr.sqlite');

      final result = await SharePlus.instance.share(
        ShareParams(
          files: [XFile(backupFile.path)],
          text: 'Backup do MeteMacha Fit - $dateStr',
        ),
      );

      if (result.status == ShareResultStatus.success) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Backup compartilhado com sucesso!')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao exportar backup: $e')),
        );
      }
    }
  }

  Future<void> _importBackup(BuildContext context) async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.any,
        withData: kIsWeb,
      );

      if (result == null || result.files.isEmpty) {
        return;
      }

      final file = result.files.first;
      if (!kIsWeb && file.path == null) return;
      if (kIsWeb && file.bytes == null) return;

      if (!context.mounted) return;
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: context.cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Restaurar Backup?'),
          content: const Text(
            'ATENÇÃO: Isso irá substituir todos os dados atuais do aplicativo pelo arquivo selecionado. Esta ação não pode ser desfeita.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Restaurar'),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      final db = ref.read(databaseProvider);
      await db.close();

      if (kIsWeb) {
        AppDatabase.bytesToImport = file.bytes;
        await deleteWebDatabase('gym_tracker');
      } else {
        final path = file.path!;
        final dbFolder = await getApplicationDocumentsDirectory();
        final dbFile = File('${dbFolder.path}/gym_tracker.sqlite');

        if (await dbFile.exists()) {
          await dbFile.delete();
        }

        await File(path).copy(dbFile.path);
      }

      ref.invalidate(databaseProvider);
      // Forçar recriação imediata do banco no mesmo loop de eventos
      ref.read(databaseProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dados restaurados com sucesso!')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao restaurar backup: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);
    final weeklyWeightsAsync = ref.watch(weeklyWeightsProvider);
    final evolution = ref.watch(evolutionProvider);
    final firstUseDate = ref.watch(firstUseDateProvider);
    final weeklySchedule = ref.watch(weeklyScheduleProvider).value ?? [];
    final scheduledWorkoutsCount = weeklySchedule.where((s) => s.dayId != null).length;
    final weeklyTarget = scheduledWorkoutsCount > 0 ? scheduledWorkoutsCount : 1;

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          // ── Header ───────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
              child: Text(
                'PERFIL',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
          ),

          // ── Stats Row ────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Card 1: Streak
                    Expanded(
                      child: Card(
                        margin: EdgeInsets.zero,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const StreakBadge(style: StreakStyle.profile),
                              const SizedBox(height: 4),
                              Text(
                                'Meta: $weeklyTarget ${weeklyTarget == 1 ? "treino" : "treinos"}/sem',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: context.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Card 2: Evolution
                    Expanded(
                      child: Card(
                        margin: EdgeInsets.zero,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'FORÇA GERAL',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: context.onSurface,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                  const Icon(
                                    Icons.trending_up_rounded,
                                    color: AppColors.success,
                                    size: 20,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${evolution >= 0 ? "+" : ""}${evolution.toStringAsFixed(1)}%',
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: evolution >= 0 ? AppColors.success : Colors.redAccent),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Carga média desde: $firstUseDate',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: context.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Form ────────────────────────────────────────────
          SliverToBoxAdapter(
            child: profileAsync.when(
              data: (profile) {
                _populate(profile);

                final photoPath = ref.watch(profilePhotoProvider);
                Widget avatarChild;
                if (photoPath == null || photoPath.isEmpty) {
                  avatarChild = const Icon(
                    Icons.person_rounded,
                    size: 36,
                    color: AppColors.primary,
                  );
                } else if (photoPath.startsWith('http') || photoPath.startsWith('https')) {
                  avatarChild = ClipRRect(
                    borderRadius: BorderRadius.circular(44),
                    child: Image.network(
                      photoPath,
                      width: 88,
                      height: 88,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.person_rounded,
                        size: 36,
                        color: AppColors.primary,
                      ),
                    ),
                  );
                } else if (kIsWeb) {
                  avatarChild = ClipRRect(
                    borderRadius: BorderRadius.circular(44),
                    child: Image.network(
                      photoPath,
                      width: 88,
                      height: 88,
                      fit: BoxFit.cover,
                    ),
                  );
                } else {
                  avatarChild = ClipRRect(
                    borderRadius: BorderRadius.circular(44),
                    child: Image.file(
                      File(photoPath),
                      width: 88,
                      height: 88,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.person_rounded,
                        size: 36,
                        color: AppColors.primary,
                      ),
                    ),
                  );
                }

                return Card(
                  margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // Avatar / ícone
                        GestureDetector(
                          onTap: () => _showPhotoOptions(context),
                          child: Stack(
                            children: [
                              CircleAvatar(
                                radius: 44,
                                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                                child: avatarChild,
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt_rounded,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Nome
                        TextField(
                          controller: _nomeCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Nome',
                            prefixIcon: Icon(Icons.badge_rounded),
                          ),
                          inputFormatters: [StringInputFormatter()],
                        ),
                        const SizedBox(height: 12),

                        // Altura + Peso
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _alturaCtrl,
                                keyboardType: TextInputType.number,
                                inputFormatters: [DecimalInputFormatter()],
                                decoration: const InputDecoration(
                                  labelText: 'Altura (cm)',
                                  prefixIcon: Icon(Icons.height_rounded),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: _pesoCtrl,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                inputFormatters: [DecimalInputFormatter()],
                                decoration: const InputDecoration(
                                  labelText: 'Peso (kg)',
                                  prefixIcon:
                                      Icon(Icons.monitor_weight_rounded),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // IMC (calculado on-the-fly)
                        _Imc(
                          peso: double.tryParse(
                              _pesoCtrl.text.replaceAll(',', '.')),
                          altura: double.tryParse(_alturaCtrl.text),
                        ),
                        const SizedBox(height: 16),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _saving ? null : _save,
                            child: _saving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Salvar'),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (e, _) => Center(child: Text('Erro: $e')),
            ),
          ),
          
          if (!kIsWeb && Platform.isAndroid)
            SliverToBoxAdapter(
              child: Card(
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: context.divider),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.system_update_rounded,
                          color: AppColors.primaryLight,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Atualizações APP',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: context.onBackground,
                              ),
                            ),
                            const SizedBox(height: 4),
                            FutureBuilder<PackageInfo>(
                              future: PackageInfo.fromPlatform(),
                              builder: (context, snapshot) {
                                final version = snapshot.data?.version ?? '...';
                                return Text(
                                  'Versão atual: v$version',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: context.onSurface,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          OtaUpdateService().checkForUpdates(context, forceShowNoUpdate: true);
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          backgroundColor: context.surfaceColor,
                          side: BorderSide(color: context.divider),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Verificar',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: context.onBackground,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          SliverToBoxAdapter(
            child: Card(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
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
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.palette_rounded,
                            color: AppColors.primaryLight,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Aparência',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: context.onBackground,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Escolha o tema visual do aplicativo',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: context.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<ThemeMode>(
                        segments: const [
                          ButtonSegment<ThemeMode>(
                            value: ThemeMode.light,
                            label: Text('Claro'),
                            icon: Icon(Icons.light_mode_rounded),
                          ),
                          ButtonSegment<ThemeMode>(
                            value: ThemeMode.dark,
                            label: Text('Escuro'),
                            icon: Icon(Icons.dark_mode_rounded),
                          ),
                          ButtonSegment<ThemeMode>(
                            value: ThemeMode.system,
                            label: Text('Sistema'),
                            icon: Icon(Icons.settings_suggest_rounded),
                          ),
                        ],
                        selected: {ref.watch(themeModeProvider)},
                        onSelectionChanged: (newSelection) {
                          ref
                              .read(themeModeProvider.notifier)
                              .setThemeMode(newSelection.first);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Card(
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
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
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.backup_rounded,
                              color: AppColors.primaryLight,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Dados & Backup',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: context.onBackground,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Exporte ou importe seus treinos e histórico',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: context.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          if (!kIsWeb) ...[
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _exportBackup(context),
                                icon: const Icon(Icons.download_rounded, size: 18),
                                label: const Text('Exportar', style: TextStyle(fontSize: 13)),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                          ],
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _importBackup(context),
                              icon: const Icon(Icons.upload_rounded, size: 18),
                              label: const Text('Importar', style: TextStyle(fontSize: 13)),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

          if (!kIsWeb)
            SliverToBoxAdapter(
              child: Card(
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
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
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.favorite_rounded,
                              color: Colors.green,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Google Health Connect',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: context.onBackground,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Sincronize pesos e treinos com o ecossistema do Google',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: context.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _healthConnectEnabled,
                            onChanged: (val) async {
                              if (val) {
                                final permitted = await HealthConnectService.instance.requestPermissions();
                                if (permitted) {
                                  await HealthConnectService.instance.setEnabled(true);
                                  if (context.mounted) {
                                    setState(() {
                                      _healthConnectEnabled = true;
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Conectado ao Google Health Connect!')),
                                    );
                                  }
                                } else {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Permissões de saúde não concedidas.'),
                                        backgroundColor: Colors.redAccent,
                                      ),
                                    );
                                  }
                                }
                              } else {
                                await HealthConnectService.instance.setEnabled(false);
                                if (context.mounted) {
                                  setState(() {
                                    _healthConnectEnabled = false;
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Sincronização desativada.')),
                                  );
                                }
                              }
                            },
                          ),
                        ],
                      ),
                      if (_healthConnectEnabled) ...[
                        const SizedBox(height: 12),
                        const Divider(),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final profileDao = ref.read(profileDaoProvider);
                              final last = await profileDao.getLatestMeasurement();
                              int syncedCount = 0;
                              
                              if (last != null && last.peso != null) {
                                final date = DateTime.tryParse(last.data) ?? DateTime.now();
                                final success = await HealthConnectService.instance.syncBodyMeasurement(
                                  weightKg: last.peso!,
                                  bodyFatPercent: last.gorduraPercentual,
                                  bmi: last.imc,
                                  dateTime: date,
                                );
                                if (success) syncedCount++;
                              }
                              
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(syncedCount > 0 
                                      ? 'Dados sincronizados com sucesso!'
                                      : 'Nenhum dado novo para sincronizar ou falha na integração.'
                                    ),
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.sync_rounded, size: 18),
                            label: const Text('Forçar Sincronização Agora', style: TextStyle(fontSize: 13)),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

          // ── Histórico de peso semanal ─────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Text(
                'HISTÓRICO SEMANAL',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ),

          weeklyWeightsAsync.when(
            data: (weights) {
              if (weights.isEmpty) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Text(
                      'Nenhum peso registrado ainda.',
                      style: TextStyle(color: context.onSurface),
                    ),
                  ),
                );
              }
              final sorted = weights.reversed.toList();
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => _WeightRow(
                    weight: sorted[i],
                    isCurrentWeek: WeekUtils.isCurrentWeek(sorted[i].semana),
                  ),
                  childCount: sorted.length,
                ),
              );
            },
            loading: () => const SliverToBoxAdapter(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, __) =>
                const SliverToBoxAdapter(child: SizedBox.shrink()),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}

class _Imc extends StatelessWidget {
  final double? peso;
  final double? altura;
  const _Imc({this.peso, this.altura});

  @override
  Widget build(BuildContext context) {
    if (peso == null || altura == null || altura! <= 0) {
      return const SizedBox.shrink();
    }
    final alturaM = altura! / 100;
    final imc = peso! / (alturaM * alturaM);
    final String classe;
    final Color cor;

    if (imc < 18.5) {
      classe = 'Abaixo do peso';
      cor = AppColors.info;
    } else if (imc < 25.0) {
      classe = 'Peso normal';
      cor = AppColors.success;
    } else if (imc < 30.0) {
      classe = 'Sobrepeso';
      cor = AppColors.warning;
    } else {
      classe = 'Obesidade';
      cor = AppColors.primary;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cor.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.calculate_rounded, size: 18, color: cor),
          const SizedBox(width: 8),
          Text(
            'IMC: ${imc.toStringAsFixed(1)}',
            style: TextStyle(color: cor, fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 8),
          Text(
            '· $classe',
            style: TextStyle(color: cor.withValues(alpha: 0.8), fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _WeightRow extends StatelessWidget {
  final WeeklyWeight weight;
  final bool isCurrentWeek;
  const _WeightRow({required this.weight, required this.isCurrentWeek});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isCurrentWeek
              ? AppColors.primary.withValues(alpha: 0.4)
              : context.divider,
        ),
      ),
      child: ListTile(
        leading: Icon(
          Icons.monitor_weight_rounded,
          color: isCurrentWeek ? AppColors.primary : context.onSurface,
          size: 22,
        ),
        title: Text(
          '${weight.peso.toStringAsFixed(1)} kg',
          style: TextStyle(
            fontWeight: isCurrentWeek ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
        subtitle: Text(WeekUtils.formatDateWithWeekday(weight.data)),
        trailing: Text(
          WeekUtils.formatWeekKey(weight.semana),
          style: TextStyle(color: context.onSurface, fontSize: 12),
        ),
      ),
    );
  }
}
