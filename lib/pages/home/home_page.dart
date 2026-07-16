// lib/pages/home/home_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/utils/file_saver.dart';

import '../../core/database/app_database.dart';
import '../../core/providers/providers.dart';
import '../../core/providers/progress_extended_provider.dart';
import '../../core/providers/alerts_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/week_utils.dart';
import '../../core/utils/premium_page_route.dart';
import '../../core/services/audio_service.dart';
import '../../widgets/weekly_weight_banner.dart';
import '../../widgets/weekly_schedule_banner.dart';
import '../../core/widgets/streak_badge.dart';
import '../profile/profile_page.dart';
import 'package:intl/intl.dart';
import '../progress/progress_page.dart';
import '../setup/setup_page.dart';
import '../setup/split_selection_page.dart';
import '../workout/workout_page.dart';
import '../../core/services/ota_update_service.dart';
import '../cardio/cardio_timer_page.dart';
import '../cardio/cardio_guide_page.dart';



class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      OtaUpdateService().checkForUpdates(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(foregroundSessionControllerProvider);
    ref.watch(widgetSyncControllerProvider);
    final splitsAsync = ref.watch(splitsProvider);
    final currentTab = ref.watch(homeTabProvider);

    return splitsAsync.when(
      data: (splits) {
        if (splits.isEmpty) {
          return const SplitSelectionPage(isOnboarding: true);
        }
        return Scaffold(
          body: IndexedStack(
            index: currentTab,
            children: const [
              _TreinoTab(),
              ProgressPage(),
              ProfilePage(),
            ],
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: currentTab,
            onTap: (index) => ref.read(homeTabProvider.notifier).state = index,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.fitness_center_rounded),
                label: 'Treino',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.bar_chart_rounded),
                label: 'Progresso',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_rounded),
                label: 'Perfil',
              ),
            ],
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('Erro ao carregar treinos: $e')),
      ),
    );
  }
}

// ─── ABA DE TREINOS (DASHBOARD) ──────────────────────────────────────────────────

class _TreinoTab extends ConsumerWidget {
  const _TreinoTab();

  void _confirmDeleteSplit(BuildContext context, WidgetRef ref, WorkoutSplit split) {
    final displayName = split.nome.isNotEmpty ? split.nome : split.tipo;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.cardColor,
        title: const Text('Excluir treino?'),
        content: Text(
          'Deseja excluir permanentemente a rotina "$displayName" e todo o histórico de execuções vinculado a ela?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              await ref.read(workoutDaoProvider).deleteSplit(split.id);
              ref.invalidate(splitsProvider);
              ref.invalidate(activeSplitProvider);
              ref.invalidate(activeSplitDaysProvider);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportSplit(BuildContext context, WidgetRef ref, WorkoutSplit split) async {
    try {
      final splitJson = await ref.read(workoutDaoProvider).exportWorkoutSplit(split.id);
      final jsonStr = jsonEncode(splitJson);
      final displayName = split.nome.isNotEmpty ? split.nome : split.tipo;
      final fileName = '${displayName.replaceAll(RegExp(r'[^\w\s\-]'), '').replaceAll(' ', '_')}.json';

      if (kIsWeb) {
        // Na Web, fazemos o download direto do arquivo JSON no navegador
        saveFileWeb(jsonStr, fileName);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Download do treino concluído!')),
          );
        }
        return;
      }

      // No Celular, usamos o compartilhamento nativo do sistema
      final tempDir = await getTemporaryDirectory();
      final file = await File('${tempDir.path}/$fileName').writeAsString(jsonStr);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: 'Fiz a exportação do meu treino "$displayName" do app MeteMarcha!',
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao exportar treino: $e')),
        );
      }
    }
  }

  Future<void> _importSplit(BuildContext context, WidgetRef ref) async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.any,
        withData: kIsWeb,
      );
      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      String jsonContent;
      if (kIsWeb) {
        if (file.bytes == null) return;
        jsonContent = utf8.decode(file.bytes!);
      } else {
        if (file.path == null) return;
        jsonContent = await File(file.path!).readAsString();
      }

      final data = jsonDecode(jsonContent) as Map<String, dynamic>;

      // Validação básica do formato
      if (data['version'] == null || data['nome'] == null || data['days'] == null) {
        throw const FormatException('Arquivo de treino inválido ou incompatível.');
      }

      final workoutDao = ref.read(workoutDaoProvider);
      final newSplitId = await workoutDao.importWorkoutSplit(data);

      // Atualiza a UI
      ref.invalidate(splitsProvider);

      if (context.mounted) {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: context.cardColor,
            title: const Text('Treino Importado!'),
            content: Text('Deseja ativar a rotina "${data['nome']}" agora?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Não'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                child: const Text('Ativar'),
              ),
            ],
          ),
        );

        if (confirm == true) {
          await workoutDao.setActiveSplit(newSplitId);
          ref.invalidate(activeSplitProvider);
          ref.invalidate(activeSplitDaysProvider);
        }

        if (!context.mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rotina de treino importada com sucesso!')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao importar treino: $e')),
        );
      }
    }
  }

  void _renameSplitDialog(BuildContext context, WidgetRef ref, WorkoutSplit split) {
    final controller = TextEditingController(text: split.nome.isNotEmpty ? split.nome : split.tipo);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.cardColor,
        title: const Text('Renomear Treino'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Nome do Treino',
            hintText: 'Ex: Treino V-Shape',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isEmpty) return;

              final db = ref.read(databaseProvider);
              await (db.update(db.workoutSplits)..where((s) => s.id.equals(split.id))).write(
                WorkoutSplitsCompanion(nome: Value(newName)),
              );

              ref.invalidate(splitsProvider);
              ref.invalidate(activeSplitProvider);

              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  void _showSplitOptions(BuildContext context, WidgetRef ref, WorkoutSplit split) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                split.nome.isNotEmpty ? split.nome : split.tipo,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Divisão do tipo: ${split.tipo}',
                style: TextStyle(color: context.onSurface, fontSize: 12),
              ),
              const Divider(height: 24),
              ListTile(
                leading: const Icon(Icons.edit_rounded, color: AppColors.primaryLight),
                title: const Text('Renomear Treino'),
                onTap: () {
                  Navigator.pop(ctx);
                  _renameSplitDialog(context, ref, split);
                },
              ),
              ListTile(
                leading: const Icon(Icons.share_rounded, color: AppColors.primaryLight),
                title: const Text('Compartilhar Treino'),
                onTap: () {
                  Navigator.pop(ctx);
                  _exportSplit(context, ref, split);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: AppColors.primary),
                title: const Text('Excluir Treino'),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmDeleteSplit(context, ref, split);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weightRegisteredAsync = ref.watch(weeklyWeightRegisteredProvider);
    final snoozed = ref.watch(weeklyWeightSnoozedProvider);
    final activeSessionAsync = ref.watch(activeSessionProvider);
    final activeSplitAsync = ref.watch(activeSplitProvider);
    final splitsAsync = ref.watch(splitsProvider);
    final daysAsync = ref.watch(activeSplitDaysProvider);
    final cardiosAsync = ref.watch(cardiosProvider);

    final membership = ref.watch(membershipSettingsProvider);
    final triggered = ref.read(membershipToastTriggeredProvider);
    final warningSnoozed = ref.watch(membershipWarningSnoozedProvider);
    if (membership.enabled && !triggered && !warningSnoozed) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final due = DateTime(membership.nextDueDate.year, membership.nextDueDate.month, membership.nextDueDate.day);
      final difference = due.difference(today).inDays;
      if (difference <= 3) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (ref.read(membershipToastTriggeredProvider)) return;
          ref.read(membershipToastTriggeredProvider.notifier).state = true;
          
          final formattedValue = membership.value.toStringAsFixed(2);
          final String msg;
          if (difference < 0) {
            msg = 'Mensalidade de R\$ $formattedValue está atrasada há ${-difference} dias! ⚠️';
          } else if (difference == 0) {
            msg = 'Mensalidade de R\$ $formattedValue vence hoje! 💳';
          } else {
            msg = 'Mensalidade de R\$ $formattedValue vence em $difference dias! 📅';
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(msg),
              backgroundColor: Colors.orangeAccent,
              behavior: SnackBarBehavior.floating,
              action: SnackBarAction(
                label: 'MARCAR PAGO',
                textColor: Colors.white,
                onPressed: () {
                  ref.read(membershipSettingsProvider.notifier).markAsPaid();
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Mensalidade registrada como paga!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
              ),
            ),
          );
        });
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text.rich(
              TextSpan(
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
                children: [
                  const TextSpan(
                    text: 'Mete ',
                    style: TextStyle(color: AppColors.primary),
                  ),
                  TextSpan(
                    text: 'Marcha',
                    style: TextStyle(color: context.onBackground),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const StreakBadge(style: StreakStyle.appBar),
          ],
        ),
          actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            tooltip: 'Configurar Treinos',
            onPressed: () {
              AudioService().playClick();
              Navigator.of(context).push(
                PremiumPageRoute(
                  page: const SetupPage(),
                  transitionType: TransitionType.slideUp,
                ),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Recarrega dados reativos invalidando os providers
          ref.invalidate(weeklyWeightRegisteredProvider);
          ref.invalidate(activeSessionProvider);
          ref.invalidate(activeSplitProvider);
          ref.invalidate(splitsProvider);
          ref.invalidate(activeSplitDaysProvider);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
             // ── Alerta de Mensalidade (Vencimento) ──────────────────────
             if (membership.enabled && !ref.watch(membershipWarningSnoozedProvider)) (() {
               final now = DateTime.now();
               final today = DateTime(now.year, now.month, now.day);
               final due = DateTime(membership.nextDueDate.year, membership.nextDueDate.month, membership.nextDueDate.day);
               final difference = due.difference(today).inDays;
               
               if (difference > 3) return const SizedBox.shrink();
               
               final formattedValue = membership.value.toStringAsFixed(2);
               final isOverdue = difference < 0;
               final isToday = difference == 0;
               
               final String text;
               if (isOverdue) {
                 text = 'Sua mensalidade de R\$ $formattedValue está atrasada há ${-difference} ${-difference == 1 ? "dia" : "dias"}!';
               } else if (isToday) {
                 text = 'Sua mensalidade de R\$ $formattedValue vence hoje!';
               } else {
                 text = 'Sua mensalidade de R\$ $formattedValue vence em $difference ${difference == 1 ? "dia" : "dias"}.';
               }
               
               return Padding(
                 padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                 child: Container(
                   decoration: BoxDecoration(
                     gradient: const LinearGradient(
                       colors: [Colors.amber, Colors.orangeAccent],
                       begin: Alignment.topLeft,
                       end: Alignment.bottomRight,
                     ),
                     borderRadius: BorderRadius.circular(16),
                     boxShadow: [
                       BoxShadow(
                         color: Colors.amber.withValues(alpha: 0.3),
                         blurRadius: 8,
                         offset: const Offset(0, 4),
                       ),
                     ],
                   ),
                   child: Padding(
                     padding: const EdgeInsets.all(16.0),
                     child: Row(
                       children: [
                         const Icon(
                           Icons.warning_amber_rounded,
                           color: Colors.white,
                           size: 28,
                         ),
                         const SizedBox(width: 12),
                         Expanded(
                           child: Column(
                             crossAxisAlignment: CrossAxisAlignment.start,
                             children: [
                               Text(
                                 isOverdue ? 'MENSALIDADE ATRASADA ⚠️' : 'ALERTA DE VENCIMENTO 💳',
                                 style: const TextStyle(
                                   color: Colors.white,
                                   fontSize: 10,
                                   fontWeight: FontWeight.w900,
                                   letterSpacing: 1.2,
                                 ),
                               ),
                               const SizedBox(height: 4),
                               Text(
                                 text,
                                 style: const TextStyle(
                                   color: Colors.white,
                                   fontSize: 13,
                                   fontWeight: FontWeight.bold,
                                   height: 1.3,
                                 ),
                               ),
                             ],
                           ),
                         ),
                         const SizedBox(width: 8),
                         TextButton(
                           onPressed: () {
                             AudioService().playClick();
                             ref.read(membershipSettingsProvider.notifier).markAsPaid();
                             ScaffoldMessenger.of(context).hideCurrentSnackBar();
                             ScaffoldMessenger.of(context).showSnackBar(
                               const SnackBar(
                                 content: Text('Mensalidade registrada como paga!'),
                                 backgroundColor: Colors.green,
                               ),
                             );
                           },
                           style: TextButton.styleFrom(
                             backgroundColor: Colors.white,
                             foregroundColor: Colors.orange.shade900,
                             shape: RoundedRectangleBorder(
                               borderRadius: BorderRadius.circular(12),
                             ),
                             padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                           ),
                           child: const Text(
                             'PAGO',
                             style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                           ),
                         ),
                         const SizedBox(width: 4),
                         IconButton(
                           icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 20),
                           onPressed: () {
                             AudioService().playClick();
                             ref.read(membershipWarningSnoozedProvider.notifier).state = true;
                             ScaffoldMessenger.of(context).hideCurrentSnackBar();
                             ScaffoldMessenger.of(context).showSnackBar(
                               const SnackBar(
                                 content: Text('Aviso ocultado temporariamente.'),
                                 duration: Duration(seconds: 3),
                               ),
                             );
                           },
                         ),
                       ],
                     ),
                   ),
                 ),
               );
             }()) else const SizedBox.shrink(),

            // ── Planejamento Semanal (Notificações) ────────────────────
            const WeeklyScheduleBanner(),

            // ── Banner de peso corporal ────────────────────────────────
            weightRegisteredAsync.when(
              data: (registered) => (registered || snoozed)
                  ? const SizedBox.shrink()
                  : const WeeklyWeightBanner(),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),

            // ── Sessão Ativa / Em Andamento ────────────────────────────
            activeSessionAsync.when(
              data: (session) {
                if (session == null) return const SizedBox.shrink();
                return _ActiveSessionCard(session: session);
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),

            const ConsistencyCalendar(),

            // ── Área de Cárdio ──────────────────────────────────────────
            Card(
              margin: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              elevation: 0,
              color: context.cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: context.divider.withValues(alpha: 0.8),
                  width: 1.5,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.directions_run_rounded,
                            color: AppColors.primaryLight,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ÁREA DE CÁRDIO',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: context.onSurface.withValues(alpha: 0.6),
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 2),
                              cardiosAsync.when(
                                data: (cardios) {
                                  if (cardios.isEmpty) {
                                    return Text(
                                      'Nenhum cárdio registrado recentemente.',
                                      style: TextStyle(fontSize: 12, color: context.onSurface),
                                    );
                                  }
                                  final last = cardios.first;
                                  final dt = DateTime.tryParse(last.data) ?? DateTime.now();
                                  final formattedDate = DateFormat('dd/MM').format(dt);
                                  final mins = last.duracaoSegundos ~/ 60;
                                  return Text(
                                    'Último: ${last.tipo} (${mins}min) em $formattedDate',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.primaryLight,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  );
                                },
                                loading: () => const SizedBox.shrink(),
                                error: (_, __) => const SizedBox.shrink(),
                              ),
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
                            onPressed: () {
                              AudioService().playClick();
                              Navigator.of(context).push(
                                PremiumPageRoute(
                                  page: const CardioGuidePage(),
                                  transitionType: TransitionType.slideRight,
                                ),
                              );
                            },
                            icon: const Icon(Icons.menu_book_rounded, size: 18),
                            label: const Text('GUIA DE CÁRDIO'),
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () {
                              AudioService().playClick();
                              Navigator.of(context).push(
                                PremiumPageRoute(
                                  page: const CardioTimerPage(),
                                  transitionType: TransitionType.slideUp,
                                ),
                              );
                            },
                            icon: const Icon(Icons.timer_outlined, size: 18),
                            label: const Text('INICIAR'),
                            style: FilledButton.styleFrom(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ── Seleção de Divisão (Split) ─────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'SUA DIVISÃO',
                        style: TextStyle(
                          color: context.onSurface,
                          fontSize: 11,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '(Segure para opções)',
                        style: TextStyle(
                          color: context.onSurface.withValues(alpha: 0.5),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  splitsAsync.when(
                    data: (splits) {
                      final activeSplit = activeSplitAsync.value;
                      return Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          ...splits.map((split) {
                            final isSelected = activeSplit?.id == split.id;
                            return GestureDetector(
                              onLongPress: () => _showSplitOptions(context, ref, split),
                              child: ChoiceChip(
                                label: Text(split.nome.isNotEmpty ? split.nome : split.tipo),
                                selected: isSelected,
                                onSelected: (selected) {
                                  if (selected) {
                                    ref
                                        .read(workoutDaoProvider)
                                        .setActiveSplit(split.id);
                                  }
                                },
                              ),
                            );
                          }),
                          ActionChip(
                            avatar: const Icon(Icons.add_rounded, size: 16, color: AppColors.primaryLight),
                            label: const Text(
                              'ADICIONAR',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                            onPressed: () {
                              AudioService().playClick();
                              Navigator.of(context).push(
                                PremiumPageRoute(
                                  page: const SplitSelectionPage(isOnboarding: false),
                                  transitionType: TransitionType.slideRight,
                                ),
                              );
                            },
                          ),
                          ActionChip(
                            avatar: const Icon(Icons.download_rounded, size: 16, color: AppColors.primaryLight),
                            label: const Text(
                              'IMPORTAR',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                            onPressed: () => _importSplit(context, ref),
                          ),
                        ],
                      );
                    },
                    loading: () => const CircularProgressIndicator(),
                    error: (e, _) => Text('Erro ao carregar divisões: $e'),
                  ),
                ],
              ),
            ),

            const Divider(),

            // ── Dias de treino da divisão ativa ────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'DIAS DE TREINO',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      AudioService().playClick();
                      Navigator.of(context).push(
                        PremiumPageRoute(
                          page: const SetupPage(),
                          transitionType: TransitionType.slideUp,
                        ),
                      );
                    },
                    icon: const Icon(Icons.edit_rounded, size: 14, color: AppColors.primaryLight),
                    label: const Text(
                      'CONFIGURAR',
                      style: TextStyle(fontSize: 12, color: AppColors.primaryLight, fontWeight: FontWeight.bold),
                    ),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
            ),

            daysAsync.when(
              data: (days) {
                if (days.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        'Nenhum dia cadastrado para esta divisão.\nUse o botão de ajuste acima para configurar.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: context.onSurface),
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: days.length,
                  itemBuilder: (_, index) {
                    final day = days[index];
                    return _DayListTile(day: day);
                  },
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Erro ao carregar dias: $e'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── CARD DE SESSÃO ATIVA ────────────────────────────────────────────────────────

class _ActiveSessionCard extends ConsumerWidget {
  final WorkoutSession session;
  const _ActiveSessionCard({required this.session});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<WorkoutDay?>(
      future: ref.read(workoutDaoProvider).getDayById(session.dayId),
      builder: (context, snapshot) {
        final day = snapshot.data;
        final name = day != null ? 'Dia ${day.letra} - ${day.nome}' : 'Treino';

        return Card(
          color: AppColors.primaryDark.withValues(alpha: 0.15),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: AppColors.primary, width: 1.2),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.flash_on_rounded, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text(
                      'TREINO EM ANDAMENTO',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        letterSpacing: 1,
                        color: AppColors.primaryLight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  name,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: 18,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Iniciado em: ${WeekUtils.formatDate(session.data)}',
                  style:
                      TextStyle(color: context.onSurface, fontSize: 12),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => _confirmCancel(context, ref),
                      style: TextButton.styleFrom(
                        foregroundColor: context.onSurface,
                      ),
                      child: const Text('CANCELAR'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        AudioService().playClick();
                        Navigator.of(context).push(
                          PremiumPageRoute(
                            page: WorkoutPage(
                              dayId: session.dayId ?? 0,
                              dayName: name,
                              sessionId: session.id,
                            ),
                            transitionType: TransitionType.slideRight,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                      ),
                      child: const Text('RETOMAR'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmCancel(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.cardColor,
        title: const Text('Cancelar treino?'),
        content: const Text(
          'Tem certeza que deseja cancelar esta sessão? Todos os logs registrados hoje serão perdidos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Voltar'),
          ),
          ElevatedButton(
            onPressed: () async {
              await ref.read(workoutDaoProvider).deleteSession(session.id);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Cancelar Treino'),
          ),
        ],
      ),
    );
  }
}

// ─── LIST TILE DO DIA DE TREINO ──────────────────────────────────────────────────

class _DayListTile extends ConsumerWidget {
  final WorkoutDay day;
  const _DayListTile({required this.day});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<List<Exercise>>(
      future: ref.read(exerciseDaoProvider).getExercisesForDay(day.id),
      builder: (context, snapshot) {
        final exercises = snapshot.data ?? [];
        final preview = exercises.isEmpty
            ? 'Nenhum exercício configurado.'
            : exercises.map((e) => e.nome).join(', ');

        return Card(
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            leading: CircleAvatar(
              backgroundColor: AppColors.getWorkoutColor(day.letra),
              foregroundColor: Colors.white,
              child: Text(
                day.letra,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(
              'Dia ${day.letra} - ${day.nome}',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                preview,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: context.onSurface),
              ),
            ),
            trailing: const Icon(Icons.chevron_right_rounded, size: 20),
            onTap: () => _showDayExercises(context, ref, exercises),
          ),
        );
      },
    );
  }

  void _showDayExercises(
      BuildContext context, WidgetRef ref, List<Exercise> exercises) {
    final dayName = 'Dia ${day.letra} - ${day.nome}';

    showModalBottomSheet(
      context: context,
      backgroundColor: context.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      dayName,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      AudioService().playClick();
                      Navigator.pop(ctx);
                      Navigator.of(context).push(
                        PremiumPageRoute(
                          page: const SetupPage(),
                          transitionType: TransitionType.slideUp,
                        ),
                      );
                    },
                    icon: const Icon(Icons.edit_rounded, size: 14, color: AppColors.primaryLight),
                    label: const Text(
                      'EDITAR',
                      style: TextStyle(color: AppColors.primaryLight, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (exercises.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'Sem exercícios cadastrados neste dia.',
                      style: TextStyle(color: context.onSurface),
                    ),
                  ),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: exercises.length,
                    itemBuilder: (_, idx) {
                      final ex = exercises[idx];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Icon(Icons.circle,
                                size: 6, color: AppColors.getWorkoutColor(day.letra)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                ex.nome,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                            Text(
                              '${ex.grupoMuscular} \u00b7 ${ex.equipamento}${ex.volume != null && ex.volume!.isNotEmpty ? ' \u00b7 ${ex.volume}' : ''}',
                              style: TextStyle(
                                  color: context.onSurface, fontSize: 11),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.getWorkoutColor(day.letra),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: exercises.isEmpty
                      ? null
                      : () async {
                          // Fecha o bottom sheet
                          Navigator.pop(ctx);

                          // Verifica se já existe uma sessão ativa
                          final active = await ref
                              .read(workoutDaoProvider)
                              .getActiveSession();
                          if (active != null) {
                            // ignore: use_build_context_synchronously
                            _showActiveConflictDialog(context, ref, active);
                            return;
                          }

                          // Cria uma nova sessão de treino
                          final sessionId = await ref
                              .read(workoutDaoProvider)
                              .insertSession(
                                WorkoutSessionsCompanion.insert(
                                  dayId: Value(day.id),
                                  data: DateTime.now().toIso8601String(),
                                  status: const Value('em_andamento'),
                                ),
                              );

                          // Abre o treino
                          if (context.mounted) {
                            AudioService().playClick();
                            Navigator.of(context).push(
                              PremiumPageRoute(
                                page: WorkoutPage(
                                  dayId: day.id,
                                  dayName: dayName,
                                  sessionId: sessionId,
                                ),
                                transitionType: TransitionType.slideRight,
                              ),
                            );
                          }
                        },
                  child: const Text('INICIAR TREINO'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showActiveConflictDialog(
      BuildContext context, WidgetRef ref, WorkoutSession active) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.cardColor,
        title: const Text('Treino em andamento'),
        content: const Text(
          'Já existe uma sessão de treino iniciada. Deseja cancelá-la para iniciar este novo treino ou prefere retomá-la?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Voltar'),
          ),
          TextButton(
            onPressed: () async {
              // Cancela treino anterior e fecha dialog
              await ref.read(workoutDaoProvider).deleteSession(active.id);
              if (ctx.mounted) Navigator.pop(ctx);
              // Inicia novo treino
              final sessionId = await ref.read(workoutDaoProvider).insertSession(
                    WorkoutSessionsCompanion.insert(
                      dayId: Value(day.id),
                      data: DateTime.now().toIso8601String(),
                      status: const Value('em_andamento'),
                    ),
                  );
              // ignore: use_build_context_synchronously
              if (context.mounted) {
                AudioService().playClick();
                Navigator.of(context).push(
                  PremiumPageRoute(
                    page: WorkoutPage(
                      dayId: day.id,
                      dayName: 'Dia ${day.letra} - ${day.nome}',
                      sessionId: sessionId,
                    ),
                    transitionType: TransitionType.slideRight,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.primaryLight),
            child: const Text('CANCELAR ANTERIOR'),
          ),
        ],
      ),
    );
  }
}

class ConsistencyCalendar extends ConsumerWidget {
  const ConsistencyCalendar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final completedSessionsAsync = ref.watch(completedSessionsProvider);
    final streak = ref.watch(streakProvider);
    final isDark = context.isDark;

    return completedSessionsAsync.when(
      data: (sessions) {
        final now = DateTime.now();
        final trainedDates = sessions.map((s) {
          try {
            final dt = DateTime.parse(s.data);
            return DateTime(dt.year, dt.month, dt.day);
          } catch (_) {
            return DateTime(1970);
          }
        }).toSet();

        int trainedInLast4Weeks = 0;

        // Render past weeks first, current week at the bottom
        final weekWidgets = List.generate(4, (wIndex) {
          final weekOffset = 3 - wIndex;
          final monday = now
              .subtract(Duration(days: now.weekday - 1))
              .subtract(Duration(days: weekOffset * 7));

          final isCurrentWeek = weekOffset == 0;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 32,
                  child: Text(
                    isCurrentWeek ? 'Atu' : 'S-$weekOffset',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: isCurrentWeek
                          ? AppColors.primaryLight
                          : context.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                ),
                ...List.generate(7, (dIndex) {
                  final day = monday.add(Duration(days: dIndex));
                  final dayDate = DateTime(day.year, day.month, day.day);
                  final isTrained = trainedDates.contains(dayDate);
                  final isToday = dayDate == DateTime(now.year, now.month, now.day);
                  final isFuture = dayDate.isAfter(DateTime(now.year, now.month, now.day));

                  if (isTrained) {
                    trainedInLast4Weeks++;
                  }

                  Color dotColor;
                  BoxBorder? border;
                  Widget? child;

                  if (isTrained) {
                    dotColor = Colors.greenAccent.withValues(alpha: 0.2);
                    border = Border.all(color: Colors.greenAccent, width: 1.5);
                    child = const Icon(
                      Icons.check_rounded,
                      size: 11,
                      color: Colors.greenAccent,
                    );
                  } else if (isToday) {
                    dotColor = AppColors.primary.withValues(alpha: 0.15);
                    border = Border.all(color: AppColors.primary, width: 1.5);
                    child = Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    );
                  } else if (isFuture) {
                    dotColor = Colors.transparent;
                    border = Border.all(
                      color: context.onSurface.withValues(alpha: 0.05),
                      width: 1,
                    );
                  } else {
                    dotColor = context.onSurface.withValues(alpha: 0.05);
                    border = Border.all(
                      color: context.onSurface.withValues(alpha: 0.1),
                      width: 1,
                    );
                  }

                  return Expanded(
                    child: Center(
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: dotColor,
                          shape: BoxShape.circle,
                          border: border,
                          boxShadow: isTrained
                              ? [
                                  BoxShadow(
                                    color: Colors.greenAccent.withValues(alpha: 0.2),
                                    blurRadius: 4,
                                    spreadRadius: 1,
                                  )
                                ]
                              : null,
                        ),
                        child: Center(child: child),
                      ),
                    ),
                  );
                }),
              ],
            ),
          );
        });

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          elevation: 0,
          color: context.cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: AppColors.primary.withValues(alpha: isDark ? 0.15 : 0.08),
              width: 1.5,
            ),
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
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.local_fire_department_rounded,
                            color: Colors.orangeAccent,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'CONSISTÊNCIA',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: context.onSurface.withValues(alpha: 0.6),
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Calendário de Treinos',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: context.onBackground,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (streak > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Colors.orangeAccent, Colors.deepOrangeAccent],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$streak ${streak == 1 ? 'SEMANA' : 'SEMANAS'} 🔥',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    const SizedBox(width: 32),
                    ...['S', 'T', 'Q', 'Q', 'S', 'S', 'D'].map((day) => Expanded(
                          child: Center(
                            child: Text(
                              day,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: context.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                          ),
                        )),
                  ],
                ),
                const SizedBox(height: 8),
                ...weekWidgets,
                const SizedBox(height: 12),
                Divider(color: context.divider, height: 1),
                const SizedBox(height: 12),
                Text(
                  trainedInLast4Weeks == 0
                      ? 'Nenhum treino registrado nas últimas 4 semanas. Vamos começar! ⚡'
                      : 'Você completou $trainedInLast4Weeks ${trainedInLast4Weeks == 1 ? 'treino' : 'treinos'} nas últimas 4 semanas. Mete Marcha! 🔥',
                  style: TextStyle(
                    fontSize: 11,
                    color: context.onSurface.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
