import '../../core/media/photo_capture.dart';
import '../../core/providers/training_focus_provider.dart';
import '../setup/training_focus_page.dart';
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
import 'package:gym_tracker/core/theme/app_theme.dart';
import 'package:gym_tracker/core/utils/week_utils.dart';
import 'package:gym_tracker/core/widgets/streak_badge.dart';
import 'package:gym_tracker/core/services/ota_update_service.dart';
import 'package:gym_tracker/core/services/auto_backup_service.dart';
import 'package:gym_tracker/pages/profile/widgets/profile_identification_card.dart';
import 'package:gym_tracker/pages/profile/widgets/profile_membership_card.dart';
import 'package:gym_tracker/pages/profile/widgets/profile_overlay_permission_card.dart';
import 'package:gym_tracker/pages/profile/widgets/profile_workout_reminder_card.dart';
import 'package:gym_tracker/pages/profile/widgets/profile_weight_row.dart';
import 'package:gym_tracker/pages/profile/widgets/profile_achievement_card.dart';
import 'package:gym_tracker/pages/profile/widgets/profile_audio_settings_card.dart';
import 'package:gym_tracker/pages/profile/widgets/profile_data_backup_card.dart';
import 'package:gym_tracker/pages/profile/widgets/profile_account_card.dart';

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

  Future<void> _changeOverlayPermission(bool val) async {
    if (val) {
      await FlutterOverlayWindow.requestPermission();
      final granted = await FlutterOverlayWindow.isPermissionGranted();
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
      final granted = await FlutterOverlayWindow.isPermissionGranted();
      if (mounted) {
        setState(() {
          _overlayPermissionGranted = granted;
        });
      }
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

    await ref.read(profileDaoProvider).upsertProfile(
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
      final pickedFile = await pickAppPhoto(
        context,
        source: source,
        maxWidth: 500,
        maxHeight: 500,
      );

      if (pickedFile == null) return;

      String finalPath;
      if (kIsWeb) {
        finalPath = pickedFile.path;
      } else {
        final appDir = await getApplicationDocumentsDirectory();
        final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final savedFile =
            await File(pickedFile.path).copy('${appDir.path}/$fileName');
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
        final dist =
            c.distanciaKm != null ? c.distanciaKm!.toStringAsFixed(2) : '';
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

      final query = db.select(db.exerciseLogs).join([
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
        final workoutName =
            day != null ? 'Treino ${day.letra} - ${day.nome}' : 'Treino Avulso';

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
        final sessions =
            await ref.read(workoutDaoProvider).watchCompletedSessions().first;

        if (splits.isEmpty && sessions.isNotEmpty) {
          await ref.read(workoutDaoProvider).insertSplit(
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
    final scheduledWorkoutsCount =
        weeklySchedule.where((s) => s.dayId != null).length;
    final weeklyTarget =
        scheduledWorkoutsCount > 0 ? scheduledWorkoutsCount : 1;

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

                return ProfileIdentificationCard(
                  photoPath: ref.watch(profilePhotoProvider),
                  nameController: _nomeCtrl,
                  heightController: _alturaCtrl,
                  weightController: _pesoCtrl,
                  saving: _saving,
                  onPhotoTap: () => _showPhotoOptions(context),
                  onSave: _save,
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
              child: ProfileOverlayPermissionCard(
                permissionGranted: _overlayPermissionGranted,
                onChanged: _changeOverlayPermission,
              ),
            ),

          const SliverToBoxAdapter(child: ProfileAccountCard()),
          SliverToBoxAdapter(
              child: ListTile(
                  leading: const Icon(Icons.tune),
                  title: const Text('Foco do treino'),
                  subtitle: Text(ref.watch(trainingFocusProvider).valueOrNull ==
                          'calistenia'
                      ? 'Calistenia'
                      : 'Musculação'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              const TrainingFocusPage(editing: true))))),

          // ── Alerta de Mensalidade ───────────────────────────────────────────
          const SliverToBoxAdapter(child: ProfileMembershipCard()),

          // ── Lembrete de Treino ──────────────────────────────────────────────
          const SliverToBoxAdapter(child: ProfileWorkoutReminderCard()),

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
            child: ProfileDataBackupCard(
              lastAutoBackupDate: _lastAutoBackupDate,
              onExportBackup: () => _exportBackup(context),
              onImportBackup: () => _importBackup(context),
              onExportCardioCsv: () => _exportCardioCSV(context),
              onExportWorkoutCsv: () => _exportWorkoutCSV(context),
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
                              final last =
                                  await profileDao.getLatestMeasurement();
                              int syncedCount = 0;

                              if (last != null && last.peso != null) {
                                final date = DateTime.tryParse(last.data) ??
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
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
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
