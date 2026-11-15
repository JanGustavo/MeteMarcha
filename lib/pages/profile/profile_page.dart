import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:gym_tracker/core/services/health_connect_service.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:drift/drift.dart' as drift;
import 'package:gym_tracker/core/database/database_helper.dart'
    if (dart.library.js_interop) 'package:gym_tracker/core/database/database_helper_web.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:gym_tracker/core/database/app_database.dart';
import 'package:gym_tracker/core/providers/providers.dart';
import 'package:gym_tracker/core/providers/progress_extended_provider.dart';
import 'package:gym_tracker/core/providers/alerts_provider.dart';
import 'package:intl/intl.dart';
import 'package:gym_tracker/core/theme/app_theme.dart';
import 'package:gym_tracker/core/utils/week_utils.dart';
import 'package:gym_tracker/core/utils/decimal_input_formatter.dart';
import 'package:gym_tracker/core/utils/string_input_formatter.dart';
import 'package:gym_tracker/core/widgets/streak_badge.dart';
import 'package:gym_tracker/core/services/ota_update_service.dart';
import 'package:gym_tracker/core/services/auto_backup_service.dart';
import 'package:gym_tracker/pages/profile/widgets/profile_bmi_banner.dart';
import 'package:gym_tracker/pages/profile/widgets/profile_weight_row.dart';
import 'package:gym_tracker/pages/profile/widgets/profile_achievement_card.dart';
import 'package:gym_tracker/pages/profile/widgets/profile_audio_settings_card.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage>
    with WidgetsBindingObserver {
  final _nomeCtrl = TextEditingController();
  final _alturaCtrl = TextEditingController();
  final _pesoCtrl = TextEditingController();

  bool _saving = false;
  bool _populated = false;
  bool _healthConnectEnabled = false;
  bool _overlayPermissionGranted = false;
  String? _lastAutoBackupDate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadHealthConnectStatus();
    _loadOverlayPermissionStatus();
  }

  void _loadHealthConnectStatus() async {
    final enabled = await HealthConnectService.instance.isEnabled();
    final lastBackup = await AutoBackupService.getLastBackupDateString();
    if (mounted) {
      setState(() {
        _healthConnectEnabled = enabled;
        _lastAutoBackupDate = lastBackup;
      });
    }
    if (enabled) {
      final dao = ref.read(profileDaoProvider);
      await HealthConnectService.instance.syncBidirectionalMeasurements(dao);
    }
  }

  void _loadOverlayPermissionStatus() async {
    if (kIsWeb || !Platform.isAndroid) return;
    final granted = await FlutterOverlayWindow.isPermissionGranted();
    if (mounted) {
      setState(() {
        _overlayPermissionGranted = granted;
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadOverlayPermissionStatus();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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

    await ref
        .read(profileDaoProvider)
        .upsertProfile(
          UserProfilesCompanion(
            nome: Value(_nomeCtrl.text.trim()),
            pesoAtual: Value(peso),
            altura: Value(altura),
          ),
        );

    // Salva também o peso desta semana
    if (peso != null) {
      await ref
          .read(profileDaoProvider)
          .upsertWeeklyWeight(WeekUtils.currentWeekKey(), peso);

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
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Perfil atualizado ✓')));
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
        final savedFile = await File(pickedFile.path)
            .copy('${appDir.path}/$fileName');
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
              leading: const Icon(
                Icons.photo_library_rounded,
                color: AppColors.primaryLight,
              ),
              title: const Text('Escolher da Galeria'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.camera_alt_rounded,
                color: AppColors.primaryLight,
              ),
              title: const Text('Tirar Foto (Câmera)'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.link_rounded,
                color: AppColors.primaryLight,
              ),
              title: const Text('Usar GitHub ou Link URL'),
              onTap: () {
                Navigator.pop(ctx);
                _showUrlInputDialog(context);
              },
            ),
            if (ref.watch(profilePhotoProvider) != null)
              ListTile(
                leading: const Icon(
                  Icons.delete_rounded,
                  color: Colors.redAccent,
                ),
                title: const Text(
                  'Remover Foto',
                  style: TextStyle(color: Colors.redAccent),
                ),
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
          : '',
    );
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
              if (!input.startsWith('http://') &&
                  !input.startsWith('https://')) {
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
      final now = DateTime.now();
      final dateStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final fileName = 'metemacha_backup_$dateStr.sqlite';

      if (kIsWeb) {
        final bytes = await exportWebDatabase('gym_tracker');
        if (bytes == null || bytes.isEmpty) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Nenhum dado encontrado para exportar!'),
              ),
            );
          }
          return;
        }

        downloadFileWeb(bytes, fileName, 'application/x-sqlite3');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Backup baixado com sucesso!')),
          );
        }
        return;
      }

      final dbFolder = await getApplicationDocumentsDirectory();
      final dbFile = File('${dbFolder.path}/gym_tracker.sqlite');

      if (!await dbFile.exists()) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Nenhum dado encontrado para exportar!'),
            ),
          );
        }
        return;
      }

      final tempDir = await getTemporaryDirectory();
      final backupFile = await dbFile.copy('${tempDir.path}/$fileName');

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

  Future<void> _exportCardioCSV(BuildContext context) async {
    try {
      final db = ref.read(databaseProvider);
      final cardios = await db.cardioDao.getAllCardios();

      if (cardios.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Nenhum dado de cárdio para exportar!'),
            ),
          );
        }
        return;
      }

      final buffer = StringBuffer();
      // CSV Header
      buffer.writeln(
        'ID,Data,Tipo,Duração (segundos),Duração (minutos),Distância (km),Calorias (kcal),Intensidade',
      );
      for (final c in cardios) {
        final durationMin = (c.duracaoSegundos / 60).toStringAsFixed(1);
        final dist = c.distanciaKm != null
            ? c.distanciaKm!.toStringAsFixed(2)
            : '';
        final cal = c.calorias != null ? c.calorias.toString() : '';
        final intensity = c.intensidade ?? '';
        buffer.writeln(
          '${c.id},${c.data},"${c.tipo}",${c.duracaoSegundos},$durationMin,$dist,$cal,"$intensity"',
        );
      }

      final csvContent = buffer.toString();
      final now = DateTime.now();
      final dateStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final filename = 'metemacha_cardio_$dateStr.csv';

      if (kIsWeb) {
        await downloadCSVWeb(csvContent, filename);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('CSV de Cárdio baixado com sucesso!')),
          );
        }
      } else {
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/$filename');
        await file.writeAsString(csvContent);

        final result = await SharePlus.instance.share(
          ShareParams(
            files: [XFile(file.path)],
            text: 'Exportação de Cárdio do MeteMacha Fit - $dateStr',
          ),
        );

        if (result.status == ShareResultStatus.success) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('CSV de Cárdio compartilhado com sucesso!'),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao exportar CSV de Cárdio: ${e.toString()}'),
          ),
        );
      }
    }
  }

  Future<void> _exportWorkoutCSV(BuildContext context) async {
    try {
      final db = ref.read(databaseProvider);

      final query =
          db.select(db.exerciseLogs).join([
              drift.innerJoin(
                db.workoutSessions,
                db.workoutSessions.id.equalsExp(db.exerciseLogs.sessionId),
              ),
              drift.leftOuterJoin(
                db.workoutDays,
                db.workoutDays.id.equalsExp(db.workoutSessions.dayId),
              ),
              drift.innerJoin(
                db.exercises,
                db.exercises.id.equalsExp(db.exerciseLogs.exerciseId),
              ),
            ])
            ..where(
              db.exerciseLogs.concluido.equals(true) &
                  db.workoutSessions.status.equals('concluido'),
            )
            ..orderBy([
              drift.OrderingTerm.asc(db.exerciseLogs.data),
              drift.OrderingTerm.asc(db.exerciseLogs.id),
            ]);

      final rows = await query.get();

      if (rows.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Nenhum dado de musculação para exportar!'),
            ),
          );
        }
        return;
      }

      final buffer = StringBuffer();
      buffer.writeln(
        'ID,Data,Treino (Sessão),Exercício,Grupo Muscular,Série,Peso (kg),Repetições,RPE,RIR,Lado,Equipamento,Observações',
      );

      for (final row in rows) {
        final log = row.readTable(db.exerciseLogs);
        final day = row.readTableOrNull(db.workoutDays);
        final exercise = row.readTable(db.exercises);

        final rpeStr = log.rpe != null ? log.rpe.toString() : '';
        final rirStr = log.rir != null ? log.rir.toString() : '';
        final ladoStr = log.lado;
        final equipStr = log.equipamento ?? exercise.equipamento;
        final obsStr = log.observacoes ?? '';
        final workoutName = day != null
            ? 'Treino ${day.letra} - ${day.nome}'
            : 'Treino Avulso';

        buffer.writeln(
          '${log.id},'
          '${log.data},'
          '"${workoutName.replaceAll('"', '""')}",'
          '"${exercise.nome.replaceAll('"', '""')}",'
          '"${exercise.grupoMuscular.replaceAll('"', '""')}",'
          '${log.serie},'
          '${log.peso},'
          '${log.repeticoes},'
          '$rpeStr,'
          '$rirStr,'
          '"$ladoStr",'
          '"${equipStr.replaceAll('"', '""')}",'
          '"${obsStr.replaceAll('"', '""')}"',
        );
      }

      final csvContent = buffer.toString();
      final now = DateTime.now();
      final dateStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final filename = 'metemacha_musculacao_$dateStr.csv';

      if (kIsWeb) {
        await downloadCSVWeb(csvContent, filename);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('CSV de Musculação baixado com sucesso!'),
            ),
          );
        }
      } else {
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/$filename');
        await file.writeAsString(csvContent);

        final result = await SharePlus.instance.share(
          ShareParams(
            files: [XFile(file.path)],
            text: 'Exportação de Musculação do MeteMacha Fit - $dateStr',
          ),
        );

        if (result.status == ShareResultStatus.success) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('CSV de Musculação compartilhado com sucesso!'),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erro ao exportar CSV de Musculação: ${e.toString()}',
            ),
          ),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
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
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
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
            const SnackBar(
              content: Text(
                'Restaurando dados... O aplicativo será recarregado.',
              ),
            ),
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

        // Invalida todos os DAOs e StreamProviders dependentes do DB
        ref.invalidate(workoutDaoProvider);
        ref.invalidate(profileDaoProvider);
        ref.invalidate(logDaoProvider);
        ref.invalidate(exerciseDaoProvider);
        ref.invalidate(splitsProvider);
        ref.invalidate(activeSplitProvider);
        ref.invalidate(activeSplitDaysProvider);
        ref.invalidate(profileProvider);
        ref.invalidate(weeklyWeightsProvider);
        ref.invalidate(bodyMeasurementsProvider);
        ref.invalidate(recentSessionsProvider);
        ref.invalidate(completedSessionsProvider);
        ref.invalidate(achievementsStatusProvider);

        // Verifica se há splits e sessões
        final splits = await ref.read(workoutDaoProvider).watchSplits().first;
        final sessions = await ref
            .read(workoutDaoProvider)
            .watchCompletedSessions()
            .first;

        if (splits.isEmpty && sessions.isNotEmpty) {
          await ref
              .read(workoutDaoProvider)
              .insertSplit(
                WorkoutSplitsCompanion.insert(
                  nome: 'Meu Treino',
                  tipo: 'CUSTOM',
                  ativo: const Value(true),
                ),
              );
          ref.invalidate(splitsProvider);
        }

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
    final scheduledWorkoutsCount = weeklySchedule
        .where((s) => s.dayId != null)
        .length;
    final weeklyTarget = scheduledWorkoutsCount > 0
        ? scheduledWorkoutsCount
        : 1;

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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
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
                                  color: evolution >= 0
                                      ? AppColors.success
                                      : Colors.redAccent,
                                ),
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
                  const Icon(
                    Icons.emoji_events_rounded,
                    color: Colors.amber,
                    size: 20,
                  ),
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
              delegate: SliverChildBuilderDelegate((context, index) {
                final list = ref.watch(achievementsStatusProvider);
                if (index >= list.length) return const SizedBox();
                return ProfileAchievementCard(status: list[index]);
              }, childCount: ref.watch(achievementsStatusProvider).length),
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
                } else if (photoPath.startsWith('http') ||
                    photoPath.startsWith('https')) {
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
                                backgroundColor: AppColors.primary.withValues(
                                  alpha: 0.12,
                                ),
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
                                      decimal: true,
                                    ),
                                inputFormatters: [DecimalInputFormatter()],
                                decoration: const InputDecoration(
                                  labelText: 'Peso (kg)',
                                  prefixIcon: Icon(
                                    Icons.monitor_weight_rounded,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // IMC (calculado on-the-fly)
                        ProfileBmiBanner(
                          peso: double.tryParse(
                            _pesoCtrl.text.replaceAll(',', '.'),
                          ),
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
                          OtaUpdateService().checkForUpdates(
                            context,
                            forceShowNoUpdate: true,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
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
                      activeThumbColor: AppColors.primaryLight,
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
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.picture_in_picture_alt_rounded,
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
                              'Painel Flutuante (Overlay)',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: context.onBackground,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Exibir controle flutuante sobre outros apps ao minimizar o treino',
                              style: TextStyle(
                                fontSize: 12,
                                color: context.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _overlayPermissionGranted,
                        onChanged: (val) async {
                          if (val) {
                            await FlutterOverlayWindow.requestPermission();
                            final granted =
                                await FlutterOverlayWindow.isPermissionGranted();
                            if (mounted) {
                              setState(() {
                                _overlayPermissionGranted = granted;
                              });
                            }
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Para desativar, remova a permissão "Sobrepor a outros apps" nas configurações.',
                                ),
                              ),
                            );
                            await FlutterOverlayWindow.requestPermission();
                            final granted =
                                await FlutterOverlayWindow.isPermissionGranted();
                            if (mounted) {
                              setState(() {
                                _overlayPermissionGranted = granted;
                              });
                            }
                          }
                        },
                        activeThumbColor: AppColors.primaryLight,
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // ── Alerta de Mensalidade ───────────────────────────────────────────
          SliverToBoxAdapter(
            child: Consumer(
              builder: (context, ref, child) {
                final membership = ref.watch(membershipSettingsProvider);
                final notifier = ref.read(membershipSettingsProvider.notifier);
                final dateFormatter = DateFormat('dd/MM/yyyy');
                final metrics = ref.watch(membershipMetricsProvider);

                String formatDuration(double hours) {
                  final totalMinutes = (hours * 60).round();
                  final h = totalMinutes ~/ 60;
                  final m = totalMinutes % 60;
                  if (h > 0) {
                    return '${h}h ${m}m';
                  }
                  return '${m}m';
                }

                Widget buildMetricRow(
                  BuildContext context,
                  String label,
                  String value, {
                  Color? valueColor,
                  bool isBold = false,
                }) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 12,
                          color: context.onSurface,
                        ),
                      ),
                      Text(
                        value,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isBold
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: valueColor ?? context.onBackground,
                        ),
                      ),
                    ],
                  );
                }

                return Card(
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
                                color: Colors.amber.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.credit_card_rounded,
                                color: Colors.amber,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Alerta de Mensalidade',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: context.onBackground,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Lembretes para pagamento e controle de mensalidade',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: context.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: membership.enabled,
                              onChanged: (val) {
                                notifier.updateSettings(enabled: val);
                              },
                              activeThumbColor: AppColors.primaryLight,
                            ),
                          ],
                        ),
                        if (membership.enabled) ...[
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                flex: 4,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Valor',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: context.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    TextFormField(
                                      initialValue: membership.value > 0
                                          ? membership.value.toStringAsFixed(2)
                                          : '',
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                            decimal: true,
                                          ),
                                      decoration: InputDecoration(
                                        prefixText: 'R\$ ',
                                        hintText: '0.00',
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 12,
                                            ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: BorderSide(
                                            color: context.divider,
                                          ),
                                        ),
                                      ),
                                      onChanged: (val) {
                                        final cleanVal = val.replaceAll(
                                          ',',
                                          '.',
                                        );
                                        final doubleVal =
                                            double.tryParse(cleanVal) ?? 0.0;
                                        notifier.updateSettings(
                                          value: doubleVal,
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 6,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Período',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: context.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    DropdownButtonFormField<int>(
                                      initialValue:
                                          membership.months == 1 ||
                                              membership.months == 12
                                          ? membership.months
                                          : 0,
                                      dropdownColor: context.cardColor,
                                      decoration: InputDecoration(
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 10,
                                            ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: BorderSide(
                                            color: context.divider,
                                          ),
                                        ),
                                      ),
                                      items: const [
                                        DropdownMenuItem(
                                          value: 1,
                                          child: Text('Mensal'),
                                        ),
                                        DropdownMenuItem(
                                          value: 12,
                                          child: Text('Anual'),
                                        ),
                                        DropdownMenuItem(
                                          value: 0,
                                          child: Text('Personalizado'),
                                        ),
                                      ],
                                      onChanged: (val) {
                                        if (val != null) {
                                          if (val > 0) {
                                            notifier.updateSettings(
                                              months: val,
                                            );
                                          } else {
                                            notifier.updateSettings(months: 3);
                                          }
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (membership.months != 1 &&
                              membership.months != 12) ...[
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Duração em Meses:',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: context.onBackground,
                                  ),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      onPressed: membership.months > 1
                                          ? () => notifier.updateSettings(
                                              months: membership.months - 1,
                                            )
                                          : null,
                                      icon: const Icon(
                                        Icons.remove_circle_outline_rounded,
                                      ),
                                    ),
                                    Text(
                                      '${membership.months}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () => notifier.updateSettings(
                                        months: membership.months + 1,
                                      ),
                                      icon: const Icon(
                                        Icons.add_circle_outline_rounded,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 16),
                          InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: membership.nextDueDate,
                                firstDate: DateTime.now().subtract(
                                  const Duration(days: 365),
                                ),
                                lastDate: DateTime.now().add(
                                  const Duration(days: 3650),
                                ),
                              );
                              if (picked != null) {
                                notifier.updateSettings(nextDueDate: picked);
                              }
                            },
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'Próximo Vencimento',
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: context.divider,
                                  ),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    dateFormatter.format(
                                      membership.nextDueDate,
                                    ),
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: context.onBackground,
                                    ),
                                  ),
                                  const Icon(
                                    Icons.calendar_month_rounded,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Quando receber alertas?',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: context.onSurface,
                            ),
                          ),
                          const SizedBox(height: 8),
                          CheckboxListTile(
                            title: const Text(
                              'No dia do vencimento (09:00)',
                              style: TextStyle(fontSize: 13),
                            ),
                            value: membership.alertOnDay,
                            onChanged: (val) {
                              if (val != null) {
                                notifier.updateSettings(alertOnDay: val);
                              }
                            },
                            activeColor: AppColors.primaryLight,
                            contentPadding: EdgeInsets.zero,
                            controlAffinity: ListTileControlAffinity.leading,
                            dense: true,
                          ),
                          CheckboxListTile(
                            title: const Text(
                              '3 dias antes (09:00)',
                              style: TextStyle(fontSize: 13),
                            ),
                            value: membership.alert3Days,
                            onChanged: (val) {
                              if (val != null) {
                                notifier.updateSettings(alert3Days: val);
                              }
                            },
                            activeColor: AppColors.primaryLight,
                            contentPadding: EdgeInsets.zero,
                            controlAffinity: ListTileControlAffinity.leading,
                            dense: true,
                          ),
                          CheckboxListTile(
                            title: const Text(
                              '1 semana antes (09:00)',
                              style: TextStyle(fontSize: 13),
                            ),
                            value: membership.alert1Week,
                            onChanged: (val) {
                              if (val != null) {
                                notifier.updateSettings(alert1Week: val);
                              }
                            },
                            activeColor: AppColors.primaryLight,
                            contentPadding: EdgeInsets.zero,
                            controlAffinity: ListTileControlAffinity.leading,
                            dense: true,
                          ),
                          if (metrics != null) ...[
                            const SizedBox(height: 16),
                            const Divider(),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                const Icon(
                                  Icons.analytics_rounded,
                                  color: AppColors.primaryLight,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Métricas do Ciclo Atual',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: context.onBackground,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: context.divider.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: context.divider.withValues(alpha: 0.1),
                                ),
                              ),
                              child: Column(
                                children: [
                                  buildMetricRow(
                                    context,
                                    'Período',
                                    '${dateFormatter.format(metrics.cycleStartDate)} - ${dateFormatter.format(metrics.cycleEndDate)}',
                                  ),
                                  const Divider(height: 16),
                                  buildMetricRow(
                                    context,
                                    'Treinos de Musculação',
                                    '${metrics.workoutCount} sessões',
                                  ),
                                  const Divider(height: 16),
                                  buildMetricRow(
                                    context,
                                    'Treinos de Cárdio',
                                    '${metrics.cardioCount} sessões',
                                  ),
                                  const Divider(height: 16),
                                  buildMetricRow(
                                    context,
                                    'Tempo Total Musculação',
                                    formatDuration(metrics.totalDurationHours),
                                  ),
                                  const Divider(height: 16),
                                  buildMetricRow(
                                    context,
                                    'Tempo Total Cárdio',
                                    formatDuration(
                                      metrics.totalCardioDurationHours,
                                    ),
                                  ),
                                  const Divider(height: 16),
                                  buildMetricRow(
                                    context,
                                    'Custo Médio por Treino',
                                    'R\$ ${metrics.costPerWorkout.toStringAsFixed(2)}',
                                    isBold: true,
                                  ),
                                  const Divider(height: 16),
                                  buildMetricRow(
                                    context,
                                    'Custo Médio por Cárdio',
                                    'R\$ ${metrics.costPerCardio.toStringAsFixed(2)}',
                                    isBold: true,
                                  ),
                                  const Divider(height: 16),
                                  buildMetricRow(
                                    context,
                                    'Custo Médio por Ida (Geral)',
                                    'R\$ ${metrics.costPerVisit.toStringAsFixed(2)}',
                                    valueColor: AppColors.primaryLight,
                                    isBold: true,
                                  ),
                                  const Divider(height: 16),
                                  buildMetricRow(
                                    context,
                                    'Custo por Hora (Total)',
                                    'R\$ ${metrics.costPerHour.toStringAsFixed(2)}',
                                    valueColor: AppColors.primaryLight,
                                    isBold: true,
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: () async {
                                await notifier.markAsPaid();
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Mensalidade de R\$ ${membership.value.toStringAsFixed(2)} paga! Próximo vencimento: ${dateFormatter.format(ref.read(membershipSettingsProvider).nextDueDate)}',
                                      ),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              },
                              icon: const Icon(Icons.check_circle_rounded),
                              label: const Text('Marcar como Pago'),
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
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
                );
              },
            ),
          ),

          // ── Lembrete de Treino ──────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Consumer(
              builder: (context, ref, child) {
                final reminder = ref.watch(workoutReminderSettingsProvider);
                final notifier = ref.read(
                  workoutReminderSettingsProvider.notifier,
                );
                final schedules = ref.watch(weeklyScheduleProvider).value ?? [];
                final activeDays = schedules
                    .where((s) => s.dayId != null)
                    .toList();

                return Card(
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
                                color: Colors.orange.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.alarm_rounded,
                                color: Colors.orange,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Lembretes de Treino',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: context.onBackground,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Receba avisos 30 minutos antes do horário do treino',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: context.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: reminder.enabled,
                              onChanged: (val) {
                                notifier.updateSettings(enabled: val);
                              },
                              activeThumbColor: AppColors.primaryLight,
                            ),
                          ],
                        ),
                        if (reminder.enabled) ...[
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 16),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text(
                              'Horário Padrão',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              'Usado nos dias de treino sem horário específico: ${reminder.globalTime}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            trailing: OutlinedButton(
                              onPressed: () async {
                                final parts = reminder.globalTime.split(':');
                                final initHour = parts.length == 2
                                    ? int.tryParse(parts[0]) ?? 8
                                    : 8;
                                final initMin = parts.length == 2
                                    ? int.tryParse(parts[1]) ?? 0
                                    : 0;
                                final picked = await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay(
                                    hour: initHour,
                                    minute: initMin,
                                  ),
                                );
                                if (picked != null) {
                                  final timeStr =
                                      '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                                  notifier.updateSettings(globalTime: timeStr);
                                }
                              },
                              child: const Text('Alterar'),
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (activeDays.isEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8.0,
                              ),
                              child: Text(
                                'Nenhum dia de treino agendado no seu planejamento semanal. Configure no seu treino.',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                  color: context.onSurface,
                                ),
                              ),
                            ),
                          ] else ...[
                            Text(
                              'Horários por Dia da Semana',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: context.onSurface,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...activeDays.map((schedule) {
                              final dia = schedule.diaSemana;
                              final hasCustom = reminder.customTimes
                                  .containsKey(dia);
                              final timeToShow =
                                  reminder.customTimes[dia] ??
                                  reminder.globalTime;

                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                elevation: 0,
                                color: context.onSurface.withValues(
                                  alpha: 0.03,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: context.divider.withValues(
                                      alpha: 0.5,
                                    ),
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12.0,
                                    vertical: 8.0,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              dia,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              hasCustom
                                                  ? 'Horário específico: $timeToShow'
                                                  : 'Padrão: $timeToShow',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: context.onSurface,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          if (hasCustom)
                                            IconButton(
                                              onPressed: () =>
                                                  notifier.removeDayTime(dia),
                                              icon: const Icon(
                                                Icons.restart_alt_rounded,
                                                size: 20,
                                              ),
                                              tooltip: 'Resetar para o padrão',
                                            ),
                                          TextButton(
                                            onPressed: () async {
                                              final parts = timeToShow.split(
                                                ':',
                                              );
                                              final initHour = parts.length == 2
                                                  ? int.tryParse(parts[0]) ?? 8
                                                  : 8;
                                              final initMin = parts.length == 2
                                                  ? int.tryParse(parts[1]) ?? 0
                                                  : 0;
                                              final picked =
                                                  await showTimePicker(
                                                    context: context,
                                                    initialTime: TimeOfDay(
                                                      hour: initHour,
                                                      minute: initMin,
                                                    ),
                                                  );
                                              if (picked != null) {
                                                final timeStr =
                                                    '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                                                notifier.updateDayTime(
                                                  dia,
                                                  timeStr,
                                                );
                                              }
                                            },
                                            child: Text(
                                              hasCustom
                                                  ? 'Alterar'
                                                  : 'Definir Horário',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          ],
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // ── Meta Semanal de Cárdio ──────────────────────────────────────────
          SliverToBoxAdapter(
            child: Consumer(
              builder: (context, ref, child) {
                final currentGoal = ref.watch(weeklyCardioGoalProvider);

                return Card(
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
                                color: AppColors.primaryLight.withValues(
                                  alpha: 0.12,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.directions_run_rounded,
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
                                    'Meta de Cárdio Semanal',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: context.onBackground,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Meta sugerida pela OMS: mínimo de 150 min',
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
                        const Divider(),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Meta semanal:',
                              style: TextStyle(
                                fontSize: 14,
                                color: context.onBackground,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  onPressed: currentGoal > 10
                                      ? () => ref
                                            .read(
                                              weeklyCardioGoalProvider.notifier,
                                            )
                                            .updateGoal(currentGoal - 10)
                                      : null,
                                  icon: const Icon(
                                    Icons.remove_circle_outline_rounded,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: context.divider.withValues(
                                      alpha: 0.05,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '$currentGoal min',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => ref
                                      .read(weeklyCardioGoalProvider.notifier)
                                      .updateGoal(currentGoal + 10),
                                  icon: const Icon(
                                    Icons.add_circle_outline_rounded,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // ── Configurações de Áudio / Sons do App ────────────────────────────
          const SliverToBoxAdapter(child: ProfileAudioSettingsCard()),

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
                              if (_lastAutoBackupDate != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Último backup automático: $_lastAutoBackupDate',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.success,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _exportBackup(context),
                            icon: const Icon(Icons.download_rounded, size: 18),
                            label: const Text(
                              'Exportar',
                              style: TextStyle(fontSize: 13),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _importBackup(context),
                            icon: const Icon(Icons.upload_rounded, size: 18),
                            label: const Text(
                              'Importar',
                              style: TextStyle(fontSize: 13),
                            ),
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
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _exportCardioCSV(context),
                            icon: const Icon(
                              Icons.directions_run_rounded,
                              size: 18,
                            ),
                            label: const Text(
                              'Cárdio (CSV)',
                              style: TextStyle(fontSize: 12),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _exportWorkoutCSV(context),
                            icon: const Icon(
                              Icons.fitness_center_rounded,
                              size: 18,
                            ),
                            label: const Text(
                              'Musculação (CSV)',
                              style: TextStyle(fontSize: 12),
                            ),
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
                                final permitted = await HealthConnectService
                                    .instance
                                    .requestPermissions();
                                if (permitted) {
                                  await HealthConnectService.instance
                                      .setEnabled(true);
                                  final dao = ref.read(profileDaoProvider);
                                  await HealthConnectService.instance
                                      .syncBidirectionalMeasurements(dao);
                                  if (context.mounted) {
                                    setState(() {
                                      _healthConnectEnabled = true;
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Conectado ao Google Health Connect!',
                                        ),
                                      ),
                                    );
                                  }
                                } else {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Permissões de saúde não concedidas.',
                                        ),
                                        backgroundColor: Colors.redAccent,
                                      ),
                                    );
                                  }
                                }
                              } else {
                                await HealthConnectService.instance.setEnabled(
                                  false,
                                );
                                if (context.mounted) {
                                  setState(() {
                                    _healthConnectEnabled = false;
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Sincronização desativada.',
                                      ),
                                    ),
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
                              final last = await profileDao
                                  .getLatestMeasurement();
                              int syncedCount = 0;

                              if (last != null && last.peso != null) {
                                final date =
                                    DateTime.tryParse(last.data) ??
                                    DateTime.now();
                                final success = await HealthConnectService
                                    .instance
                                    .syncBodyMeasurement(
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
                                    content: Text(
                                      syncedCount > 0
                                          ? 'Dados sincronizados com sucesso!'
                                          : 'Nenhum dado novo para sincronizar ou falha na integração.',
                                    ),
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.sync_rounded, size: 18),
                            label: const Text(
                              'Forçar Sincronização Agora',
                              style: TextStyle(fontSize: 13),
                            ),
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
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(letterSpacing: 1.5, fontWeight: FontWeight.w600),
              ),
            ),
          ),

          weeklyWeightsAsync.when(
            data: (weights) {
              if (weights.isEmpty) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
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
                  (_, i) => ProfileWeightRow(
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
