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
import '../../core/constants/achievements.dart';
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
          SnackBar(content: Text('Erro ao escolher imagem: ${e.toString()}')),
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
          SnackBar(content: Text('Erro ao exportar backup: ${e.toString()}')),
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
        saveBackupBytesToLocalStorage(file.bytes!);
        await deleteWebDatabase('gym_tracker');

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Restaurando dados... O aplicativo será recarregado.')),
          );
        }
        await Future.delayed(const Duration(milliseconds: 1000));
        reloadWebPage();
        return;
      } else {
        final path = file.path!;
        final dbFolder = await getApplicationDocumentsDirectory();
        final dbFile = File('${dbFolder.path}/gym_tracker.sqlite');

        if (await dbFile.exists()) {
          await dbFile.delete();
        }

        await File(path).copy(dbFile.path);

        ref.invalidate(databaseProvider);
        ref.read(databaseProvider);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Dados restaurados com sucesso!')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao restaurar backup: ${e.toString()}')),
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

          // ── Conquistas / Achievements Title ──────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  const Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'CONQUISTAS',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: context.onBackground,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Conquistas / Achievements Grid ───────────────────
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 0.95,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final list = ref.watch(achievementsStatusProvider);
                  if (index >= list.length) return const SizedBox();
                  return _AchievementCard(status: list[index]);
                },
                childCount: ref.watch(achievementsStatusProvider).length,
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
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.fitness_center_rounded,
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
                            'RPE / RIR',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: context.onBackground,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Registrar esforço percebido (RPE) e repetições de reserva (RIR) nas séries',
                            style: TextStyle(
                              fontSize: 12,
                              color: context.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: ref.watch(rpeEnabledProvider),
                      onChanged: (val) {
                        ref.read(rpeEnabledProvider.notifier).toggle(val);
                      },
                      activeColor: AppColors.primaryLight,
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

class _AchievementCard extends StatelessWidget {
  final AchievementStatus status;

  const _AchievementCard({required this.status});

  Widget _buildEmblem(BuildContext context, {double size = 48}) {
    final ach = status.achievement;
    final levelIdx = status.unlockedLevelIndex;
    final isLocked = levelIdx == -1;

    Gradient borderGradient;
    Gradient bgGradient;
    String badgeEmoji;
    String levelName;

    if (isLocked) {
      bgGradient = const LinearGradient(
        colors: [Color(0xFF2C2C2C), Color(0xFF1E1E1E)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );
      borderGradient = const LinearGradient(
        colors: [Color(0xFF444444), Color(0xFF333333)],
      );
      badgeEmoji = '🔒';
    } else {
      final currentLevel = ach.levels[levelIdx];
      levelName = currentLevel.name;
      badgeEmoji = ach.emoji;
      if (levelName == 'Bronze') {
        bgGradient = const LinearGradient(
          colors: [Color(0xFF8C5230), Color(0xFFE2A785), Color(0xFF8C5230)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
        borderGradient = const LinearGradient(
          colors: [Color(0xFFCD7F32), Color(0xFFFFE5D9), Color(0xFFCD7F32)],
        );
      } else if (levelName == 'Prata') {
        bgGradient = const LinearGradient(
          colors: [Color(0xFF6B7B8C), Color(0xFFEBF3FA), Color(0xFF6B7B8C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
        borderGradient = const LinearGradient(
          colors: [Color(0xFFB0B8C0), Color(0xFFFFFFFF), Color(0xFFB0B8C0)],
        );
      } else {
        bgGradient = const LinearGradient(
          colors: [Color(0xFFB59410), Color(0xFFFFFAAF), Color(0xFFB59410)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
        borderGradient = const LinearGradient(
          colors: [Color(0xFFFFD700), Color(0xFFFFFFE0), Color(0xFFFFD700)],
        );
      }
    }

    final double width = size;
    final double height = size * 1.15;

    return ClipPath(
      clipper: HexagonClipper(),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          gradient: borderGradient,
        ),
        padding: const EdgeInsets.all(2.0),
        child: ClipPath(
          clipper: HexagonClipper(),
          child: Container(
            decoration: BoxDecoration(
              gradient: bgGradient,
            ),
            child: Center(
              child: Text(
                badgeEmoji,
                style: TextStyle(
                  fontSize: size * 0.45,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final ach = status.achievement;
    final levelIdx = status.unlockedLevelIndex;
    final isLocked = levelIdx == -1;

    Color barColor = Colors.grey;
    if (!isLocked) {
      final levelName = ach.levels[levelIdx].name;
      if (levelName == 'Bronze') {
        barColor = const Color(0xFFCD7F32);
      } else if (levelName == 'Prata') {
        barColor = const Color(0xFFB0B8C0);
      } else {
        barColor = const Color(0xFFFFD700);
      }
    }

    return InkWell(
      onTap: () => _showAchievementDetail(context),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 2.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildEmblem(context, size: 52),
            const SizedBox(height: 6),
            Text(
              ach.shortTitle,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isLocked ? context.onSurface.withValues(alpha: 0.5) : context.onBackground,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 5),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(1.5),
                child: LinearProgressIndicator(
                  value: status.progress,
                  minHeight: 3,
                  backgroundColor: isDark ? Colors.white10 : Colors.black12,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isLocked ? AppColors.primary : barColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAchievementDetail(BuildContext context) {
    final ach = status.achievement;
    final levelIdx = status.unlockedLevelIndex;
    final isDark = context.isDark;

    showModalBottomSheet(
      context: context,
      backgroundColor: context.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildEmblem(context, size: 56),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ach.title,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: context.onBackground,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            ach.description,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: context.divider.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Progresso Atual:',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                      Text(
                        _formatValue(status.currentValue, ach.type),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  status.nextTargetLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryLight,
                  ),
                ),
                const SizedBox(height: 16),
                Column(
                  children: List.generate(ach.levels.length, (index) {
                    final level = ach.levels[index];
                    final isUnlocked = levelIdx >= index;
                    final isNext = levelIdx + 1 == index;

                    Color color;
                    if (level.name == 'Bronze') {
                      color = const Color(0xFFCD7F32);
                    } else if (level.name == 'Prata') {
                      color = const Color(0xFFB0B8C0);
                    } else {
                      color = const Color(0xFFFFD700);
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: isUnlocked ? color.withValues(alpha: 0.05) : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isUnlocked
                              ? color.withValues(alpha: 0.3)
                              : isNext
                                  ? AppColors.primary.withValues(alpha: 0.4)
                                  : context.divider.withValues(alpha: 0.15),
                          width: isUnlocked || isNext ? 1.5 : 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(level.icon, style: const TextStyle(fontSize: 20)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  level.name,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: isUnlocked ? color : context.onBackground.withValues(alpha: 0.7),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Exige: ${_formatValue(level.value, ach.type)}',
                                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                          if (isUnlocked)
                            const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 18)
                          else if (isNext)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Próximo',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryLight,
                                ),
                              ),
                            )
                          else
                            const Icon(Icons.lock_outline_rounded, color: Colors.grey, size: 16),
                        ],
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatValue(double val, AchievementType type) {
    if (type == AchievementType.exercise1rm) {
      return '${val.toStringAsFixed(1)} kg';
    } else if (type == AchievementType.totalVolumeTons) {
      return '${val.toStringAsFixed(1)} t';
    } else if (type == AchievementType.totalWorkouts) {
      return '${val.toInt()} ${val.toInt() == 1 ? "treino" : "treinos"}';
    } else if (type == AchievementType.weekStreak) {
      return '${val.toInt()} ${val.toInt() == 1 ? "semana" : "semanas"}';
    } else {
      return '${val.toInt()} ${val.toInt() == 1 ? "série" : "séries"}';
    }
  }
}

class HexagonClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final w = size.width;
    final h = size.height;
    
    // Vertical pointed hexagon (point at top center and bottom center)
    path.moveTo(w * 0.5, 0);
    path.lineTo(w, h * 0.25);
    path.lineTo(w, h * 0.75);
    path.lineTo(w * 0.5, h);
    path.lineTo(0, h * 0.75);
    path.lineTo(0, h * 0.25);
    path.close();
    
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
