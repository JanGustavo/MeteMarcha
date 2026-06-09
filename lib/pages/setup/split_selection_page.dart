// lib/pages/setup/split_selection_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/database/app_database.dart';
import '../../core/providers/providers.dart';
import '../../core/theme/app_theme.dart';
import 'setup_page.dart';
import '../../main.dart';

const bool groqBeta = true;

class SplitSelectionPage extends ConsumerWidget {
  final bool isOnboarding;
  const SplitSelectionPage({super.key, this.isOnboarding = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: isOnboarding
          ? null
          : AppBar(
              title: const Text('ADICIONAR TREINO'),
              backgroundColor: Colors.transparent,
              elevation: 0,
            ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isOnboarding) ...[
                const SizedBox(height: 20),
                // Header do App
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.fitness_center_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'MeteMacha',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Título
                Text(
                  'Selecione seu\nTreino',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        fontSize: 42,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                        letterSpacing: -1.5,
                        color: Colors.white,
                      ),
                ),
                const SizedBox(height: 24),
              ] else ...[
                const SizedBox(height: 16),
                const Text(
                  'Selecione uma divisão abaixo para adicioná-la à sua lista de treinos ativos.',
                  style: TextStyle(
                    color: AppColors.onSurface,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Grid 2x2 dos Cards de Treino
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.85,
                  children: [
                    _buildSplitCard(
                      context,
                      ref,
                      tipo: 'ABC',
                      richTitle: RichText(
                        text: const TextSpan(
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                          children: [
                            TextSpan(text: 'A', style: TextStyle(color: Colors.white)),
                            TextSpan(text: 'B', style: TextStyle(color: AppColors.primaryLight)),
                            TextSpan(text: 'C', style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                      subtitle: 'Básico - 3 dias/sem.',
                      iconWidget: _buildWeightStackIcon(),
                      desc: 'Ideal para iniciantes ou quem tem tempo limitado. Foco em consistência.',
                      daysInfo: const [
                        'Dia A: Peito, Ombro e Tríceps',
                        'Dia B: Costas e Bíceps',
                        'Dia C: Perna e Core',
                      ],
                    ),
                    _buildSplitCard(
                      context,
                      ref,
                      tipo: 'ABCD',
                      richTitle: RichText(
                        text: const TextSpan(
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                          children: [
                            TextSpan(text: 'A', style: TextStyle(color: Colors.white)),
                            TextSpan(text: 'B', style: TextStyle(color: AppColors.primaryLight)),
                            TextSpan(text: 'C', style: TextStyle(color: Colors.white)),
                            TextSpan(text: 'D', style: TextStyle(color: AppColors.primaryLight)),
                          ],
                        ),
                      ),
                      subtitle: 'Intermediário - 4 dias/sem.',
                      iconWidget: _buildDumbbellsIcon(),
                      desc: 'Excelente para quem já treina e quer isolar grupos musculares específicos.',
                      daysInfo: const [
                        'Dia A: Peito e Tríceps',
                        'Dia B: Costas e Bíceps',
                        'Dia C: Ombro e Core',
                        'Dia D: Perna Completa',
                      ],
                    ),
                    _buildSplitCard(
                      context,
                      ref,
                      tipo: 'ABCDE',
                      richTitle: RichText(
                        text: const TextSpan(
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                          children: [
                            TextSpan(text: 'A', style: TextStyle(color: Colors.white)),
                            TextSpan(text: 'B', style: TextStyle(color: AppColors.primaryLight)),
                            TextSpan(text: 'C', style: TextStyle(color: Colors.white)),
                            TextSpan(text: 'D', style: TextStyle(color: AppColors.primaryLight)),
                            TextSpan(text: 'E', style: TextStyle(color: AppColors.primaryLight)),
                          ],
                        ),
                      ),
                      subtitle: 'Avançado - 5 dias/sem.',
                      iconWidget: _buildKettlebellIcon(),
                      desc: 'Foco alto em volume e intensidade, treinando quase todos os dias da semana.',
                      daysInfo: const [
                        'Dia A: Peito',
                        'Dia B: Costas',
                        'Dia C: Ombro',
                        'Dia D: Perna',
                        'Dia E: Braços (Bíceps e Tríceps)',
                      ],
                    ),
                    _buildSplitCard(
                      context,
                      ref,
                      tipo: 'CUSTOM',
                      richTitle: const Text(
                        'CUSTOM',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                          color: Colors.white,
                        ),
                      ),
                      subtitle: 'Crie sua própria rotina',
                      iconWidget: const Icon(
                        Icons.assignment_rounded,
                        size: 44,
                        color: AppColors.onSurface,
                      ),
                      desc: 'Crie um treino do zero, adicionando dias e exercícios conforme sua necessidade.',
                      daysInfo: const [
                        'Dia A: Meu Treino A (Personalizado)',
                      ],
                    ),
                  ],
                ),
              ),

              // Botão Importar JSON
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primary, width: 1.2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: () => _showImportJsonDialog(context, ref),
                    icon: const Icon(Icons.code_rounded, color: AppColors.primaryLight),
                    label: const Text(
                      'IMPORTAR TREINO (JSON)',
                      style: TextStyle(
                        color: AppColors.primaryLight,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ),

              // Footer Text
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Toque para ver os detalhes',
                        style: TextStyle(color: AppColors.onSurface, fontSize: 13),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.star_rounded, size: 14, color: AppColors.primaryLight),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Card do Grid
  Widget _buildSplitCard(
    BuildContext context,
    WidgetRef ref, {
    required String tipo,
    required Widget richTitle,
    required String subtitle,
    required Widget iconWidget,
    required String desc,
    required List<String> daysInfo,
  }) {
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      color: AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.divider, width: 1),
      ),
      child: InkWell(
        onTap: () => _showDetailsSheet(
          context,
          ref,
          tipo: tipo,
          titleWidget: richTitle,
          subtitle: subtitle,
          desc: desc,
          daysInfo: daysInfo,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título (A B C, etc.)
              richTitle,
              const SizedBox(height: 6),
              // Subtítulo
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.onSurface,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              // Ícone Customizado no centro/fim
              Center(child: iconWidget),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  // Detalhes em Bottom Sheet
  void _showDetailsSheet(
    BuildContext context,
    WidgetRef ref, {
    required String tipo,
    required Widget titleWidget,
    required String subtitle,
    required String desc,
    required List<String> daysInfo,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      titleWidget,
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(color: AppColors.onSurface, fontSize: 13),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Divider(height: 24),
              const Text(
                'COMO FUNCIONA:',
                style: TextStyle(
                  color: AppColors.primaryLight,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                desc,
                style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 16),
              const Text(
                'DIAS E GRUPOS MUSCULARES:',
                style: TextStyle(
                  color: AppColors.primaryLight,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              ...daysInfo.map(
                (info) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline_rounded,
                          size: 16, color: AppColors.primaryLight),
                      const SizedBox(width: 8),
                      Text(
                        info,
                        style: const TextStyle(color: AppColors.onBackground, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(ctx); // Fecha o bottom sheet

                    // Adiciona o treino selecionado no banco
                    await ref.read(workoutDaoProvider).addSplit(tipo);
                    ref.invalidate(splitsProvider);
                    ref.invalidate(activeSplitProvider);
                    ref.invalidate(activeSplitDaysProvider);

                    final nav = navigatorKey.currentState;
                    final rootContext = navigatorKey.currentContext;

                    if (rootContext != null && rootContext.mounted) {
                      ScaffoldMessenger.of(rootContext).showSnackBar(
                        const SnackBar(content: Text('Treino adicionado com sucesso! ✓')),
                      );
                    }

                    if (!isOnboarding && context.mounted) {
                      Navigator.pop(context); // Volta ao Dashboard se não estiver no onboarding
                    }

                    nav?.push(
                      MaterialPageRoute(builder: (_) => const SetupPage(initialTab: 2)),
                    );
                  },
                  child: const Text('ATIVAR ESTE TREINO'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── DESENHO DOS ÍCONES CUSTOMIZADOS ──────────────────────────────────────────

  // Ícone de pilha de anilhas
  Widget _buildWeightStackIcon() {
    return SizedBox(
      height: 50,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(4, (index) {
          final width = 36.0 + (index * 8.0);
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.0),
            child: Container(
              width: width,
              height: 6,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.3 + (index * 0.15)),
                    AppColors.primaryLight.withValues(alpha: 0.5 + (index * 0.15)),
                  ],
                ),
                borderRadius: BorderRadius.circular(3),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.6),
                  width: 1,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // Ícone de halteres cruzados/paralelos
  Widget _buildDumbbellsIcon() {
    Widget dumbbell() {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 18,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primaryDark, AppColors.primaryLight],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          Container(
            width: 16,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          Container(
            width: 8,
            height: 18,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primaryDark, AppColors.primaryLight],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ],
      );
    }

    return SizedBox(
      height: 50,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          dumbbell(),
          const SizedBox(height: 6),
          Transform.translate(
            offset: const Offset(10, 0),
            child: dumbbell(),
          ),
        ],
      ),
    );
  }

  // Ícone de Kettlebell
  Widget _buildKettlebellIcon() {
    return SizedBox(
      width: 44,
      height: 50,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Alça
          Positioned(
            top: 4,
            child: Container(
              width: 28,
              height: 22,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.7),
                  width: 4.5,
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              ),
            ),
          ),
          // Corpo redondo
          Positioned(
            bottom: 4,
            child: Container(
               width: 38,
               height: 32,
               decoration: BoxDecoration(
                 gradient: const LinearGradient(
                   colors: [AppColors.primaryDark, AppColors.primaryLight],
                   begin: Alignment.topLeft,
                   end: Alignment.bottomRight,
                 ),
                 borderRadius: BorderRadius.circular(19),
                 border: Border.all(
                   color: AppColors.primaryLight.withValues(alpha: 0.8),
                   width: 1,
                 ),
               ),
             ),
          ),
          // Detalhe de brilho/texto
          Positioned(
            bottom: 12,
            child: Text(
              'KG',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 9,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showImportJsonDialog(BuildContext context, WidgetRef ref) {
    final textCtrl = TextEditingController();
    bool clearUnused = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppColors.card,
          title: const Row(
            children: [
              Icon(Icons.code_rounded, color: AppColors.primary),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Importar Treino (JSON)',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Escolha uma das opções para formatar seu treino:',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 8),
                const Text(
                  '💡 Opção 1 (Recomendada): Clique em "Formatar com IA", cole seu treino em texto livre (ex: do WhatsApp) e ela vai organizá-lo para você.\n\n'
                  '📋 Opção 2 (Manual): Clique em "Copiar Instruções" para copiar o prompt modelo. Cole-o no ChatGPT/Claude, adicione seu treino no final e depois copie o resultado gerado de volta no campo abaixo.',
                  style: TextStyle(fontSize: 12, color: AppColors.onSurface, height: 1.3),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (groqBeta) ...[
                      Expanded(
                        child: TextButton.icon(
                          onPressed: () => _showAiImportDialog(context, textCtrl),
                          icon: const Icon(Icons.psychology_rounded, color: AppColors.primaryLight),
                          label: const Text(
                            'Formatar com IA',
                            style: TextStyle(color: AppColors.primaryLight),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: TextButton.icon(
                        onPressed: () async {
                          const promptTemplate = 'Olá! Quero que formate o meu treino para que eu possa importá-lo em um aplicativo.\n'
                              'Por favor, analise a lista de exercícios a seguir e converta-a estritamente no formato estruturado (JSON) abaixo. Não escreva nenhuma conversa ou explicação na resposta, apenas o bloco de texto estruturado final.\n\n'
                              'Estrutura esperada:\n'
                              '{\n'
                              '  "nome": "Nome do Treino (ex: Hipertrofia)",\n'
                              '  "tipo": "ABC", // ABC, ABCD, ABCDE ou CUSTOM\n'
                              '  "dias": [\n'
                              '    {\n'
                              '      "letra": "A",\n'
                              '      "nome": "Nome do Dia (ex: Peito e Tríceps)",\n'
                              '      "exercicios": [\n'
                              '        {\n'
                              '          "nome": "Nome do Exercício (ex: Supino Reto)",\n'
                              '          "grupoMuscular": "Peito", // Peito, Costas, Ombro, Tríceps, Bíceps, Perna, Core ou Glúteo\n'
                              '          "equipamento": "Barra", // Livre, Barra, Haltere, Cabo, Máquina, Peso Corporal ou Smith\n'
                              '          "isUnilateral": false,\n'
                              '          "tempoDescansoSegundos": 90,\n'
                              '          "volume": "4x10"\n'
                              '        }\n'
                              '      ]\n'
                              '    }\n'
                              '  ]\n'
                              '}\n\n'
                              'Aqui está a lista do meu treino para você formatar:\n'
                              '[SUBSTITUA ESTE TEXTO PELO SEU TREINO DO WHATSAPP OU ANOTAÇÕES]';

                          await Clipboard.setData(const ClipboardData(text: promptTemplate));
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Instruções para a IA copiadas! Cole no ChatGPT/Claude. ✓'),
                                duration: Duration(seconds: 3),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.copy_all_rounded, size: 16),
                        label: const Text(
                          'Copiar Instruções',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: textCtrl,
                  maxLines: 10,
                  style: const TextStyle(
                      fontFamily: 'monospace', fontSize: 12),
                  decoration: const InputDecoration(
                    hintText: 'Cole o código JSON aqui...',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    SizedBox(
                      height: 24,
                      width: 24,
                      child: Checkbox(
                        value: clearUnused,
                        activeColor: AppColors.primary,
                        onChanged: (val) {
                          setState(() {
                            clearUnused = val ?? false;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Limpar biblioteca (remove exercícios padrão não utilizados)',
                        style: TextStyle(fontSize: 13, color: AppColors.onBackground),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final input = textCtrl.text.trim();
                if (input.isEmpty) return;

                try {
                  final data = jsonDecode(input);
                  if (data is! Map<String, dynamic>) {
                    throw const FormatException('O JSON deve ser um objeto.');
                  }
                  if (!data.containsKey('nome') || !data.containsKey('dias')) {
                    throw const FormatException(
                        'Campos obrigatórios ausentes ("nome" ou "dias").');
                  }

                  final dias = data['dias'];
                  if (dias is! List) {
                    throw const FormatException(
                        'O campo "dias" deve ser uma lista.');
                  }

                  Navigator.pop(ctx);

                  final db = ref.read(databaseProvider);
                  await db.transaction(() async {
                    if (clearUnused) {
                      await ref.read(exerciseDaoProvider).deleteUnusedExercises();
                    }

                    final splitId = await ref.read(workoutDaoProvider).insertSplit(
                          WorkoutSplitsCompanion.insert(
                            tipo: data['tipo'] ?? 'CUSTOM',
                            nome: data['nome'],
                            ativo: const Value(false),
                          ),
                        );

                    final allExercises =
                        await ref.read(exerciseDaoProvider).getAll();

                    for (final dayObj in dias) {
                      if (dayObj is! Map<String, dynamic>) continue;
                      
                      final letra = dayObj['letra'] ?? 'A';
                      final nomeDia = dayObj['nome'] ?? 'Treino';
                      final dayId = await ref.read(workoutDaoProvider).insertDay(
                            WorkoutDaysCompanion.insert(
                              splitId: splitId,
                              letra: letra,
                              nome: nomeDia,
                            ),
                          );

                      final exercisesList = dayObj['exercicios'];
                      if (exercisesList is! List) continue;

                      for (int i = 0; i < exercisesList.length; i++) {
                        final exObj = exercisesList[i];
                        if (exObj is! Map<String, dynamic>) continue;

                        final exName = exObj['nome']?.toString().trim() ?? '';
                        if (exName.isEmpty) continue;

                        final normalizedSearchName = exName.toLowerCase();
                        Exercise? foundEx;
                        for (final e in allExercises) {
                          if (e.nome.trim().toLowerCase() ==
                              normalizedSearchName) {
                            foundEx = e;
                            break;
                          }
                        }

                        int exId;
                        if (foundEx != null) {
                          exId = foundEx.id;
                        } else {
                          exId = await ref.read(exerciseDaoProvider).insertExercise(
                                ExercisesCompanion.insert(
                                  nome: exName,
                                  grupoMuscular:
                                      exObj['grupoMuscular']?.toString() ??
                                          'Peito',
                                  equipamento: Value(
                                      exObj['equipamento']?.toString() ??
                                          'Livre'),
                                  isUnilateral: Value(
                                      exObj['isUnilateral'] as bool? ?? false),
                                  tempoDescansoSegundos: Value(
                                      exObj['tempoDescansoSegundos'] as int? ??
                                          90),
                                  volume: Value(exObj['volume']?.toString()),
                                  link: Value(exObj['link']?.toString()),
                                  vezesFeito: const Value(0),
                                ),
                              );
                        }

                        await ref.read(exerciseDaoProvider).linkExerciseToDay(
                              WorkoutDayExercisesCompanion.insert(
                                dayId: dayId,
                                exerciseId: exId,
                                ordem: i,
                              ),
                            );
                      }
                    }

                    await ref.read(workoutDaoProvider).setActiveSplit(splitId);
                  });

                  ref.invalidate(splitsProvider);
                  ref.invalidate(activeSplitProvider);
                  ref.invalidate(activeSplitDaysProvider);

                  final nav = navigatorKey.currentState;
                  final rootContext = navigatorKey.currentContext;

                  if (rootContext != null && rootContext.mounted) {
                    ScaffoldMessenger.of(rootContext).showSnackBar(
                      const SnackBar(
                        content: Text('Treino importado e ativado com sucesso! ✓'),
                      ),
                    );
                  }

                  if (!isOnboarding && context.mounted) {
                    Navigator.pop(context);
                  }

                  nav?.push(
                    MaterialPageRoute(builder: (_) => const SetupPage(initialTab: 2)),
                  );
                } catch (e) {
                  if (context.mounted) {
                    showDialog(
                      context: context,
                      builder: (errCtx) => AlertDialog(
                        backgroundColor: AppColors.card,
                        title: const Text('Erro na Importação'),
                        content: Text(
                            'Não foi possível importar o treino. Detalhes:\n$e'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(errCtx),
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                  }
                }
              },
              child: const Text('Importar'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAiImportDialog(BuildContext context, TextEditingController mainJsonCtrl) {
    final rawTextCtrl = TextEditingController();
    bool isLoading = false;
    String errorMessage = '';

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: AppColors.card,
            title: const Row(
              children: [
                Icon(Icons.psychology_rounded, color: AppColors.primaryLight),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Formatar Treino com IA',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Cole o texto bruto do seu treino (ex: copiado do WhatsApp ou Notas). A IA vai organizá-lo e formatá-lo para o aplicativo automaticamente.',
                    style: TextStyle(fontSize: 13, color: AppColors.onSurface),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: rawTextCtrl,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      hintText: 'Ex:\nSegunda: Peito e Tríceps\n- Supino Reto 4x10\n- Tríceps Testa 3x12...',
                      alignLabelWithHint: true,
                    ),
                  ),
                  if (errorMessage.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      errorMessage,
                      style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isLoading ? null : () => Navigator.pop(ctx),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: isLoading
                    ? null
                    : () async {
                        final rawText = rawTextCtrl.text.trim();
                        
                        if (rawText.isEmpty) {
                          setState(() {
                            errorMessage = 'Insira o texto do treino.';
                          });
                          return;
                        }
                        
                        setState(() {
                          isLoading = true;
                          errorMessage = '';
                        });
                        
                        try {
                          // Obtém a API Key mockada ou a configurada anteriormente
                          final prefs = await SharedPreferences.getInstance();
                          final apiKey = prefs.getString('groq_api_key') ?? ('gsk_0U02Xmja' '1UEmgIbrgdUkWGdyb3FYQUYZfpEQGVx0CSYa9Hz0RHIS');
                          
                          final jsonResult = await _processWorkoutWithGroq(rawText, apiKey);
                          
                          mainJsonCtrl.text = jsonResult;
                          
                          if (ctx.mounted) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Treino formatado com sucesso! ✓'),
                              ),
                            );
                          }
                        } catch (e) {
                          String errorMsg = 'Erro ao formatar: $e';
                          final errStr = e.toString();
                          if (errStr.contains('SocketException') || errStr.contains('Failed host lookup') || errStr.contains('errno = 7')) {
                            errorMsg = 'Sem conexão com a internet. Verifique sua conexão e tente novamente.';
                          }
                          setState(() {
                            isLoading = false;
                            errorMessage = errorMsg;
                          });
                        }
                      },
                child: isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Formatar'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<String> _processWorkoutWithGroq(String rawText, String apiKey) async {
    final url = Uri.parse('https://api.groq.com/openai/v1/chat/completions');
    
    const systemPrompt = '''
Você é um assistente especialista em educação física e análise de dados. Seu objetivo é converter um texto livre contendo uma rotina de treinos (que pode estar em português, inglês, etc., copiado do WhatsApp ou anotações) em um objeto JSON válido que descreve a rotina de exercícios.

O JSON gerado DEVE seguir estritamente a seguinte estrutura:
{
  "nome": "Nome do Treino (ex: Hipertrofia)",
  "tipo": "ABC", // Deve ser: "ABC", "ABCD", "ABCDE" ou "CUSTOM"
  "dias": [
    {
      "letra": "A", // "A", "B", "C", "D", "E" sequencialmente
      "nome": "Nome do Dia (ex: Peito e Tríceps)",
      "exercicios": [
        {
          "nome": "Nome do Exercício (ex: Supino Reto)",
          "grupoMuscular": "Peito", // DEVE ser um destes exatos valores: Peito, Costas, Ombro, Tríceps, Bíceps, Perna, Core, Glúteo
          "equipamento": "Barra", // DEVE ser um destes exatos valores: Livre, Barra, Haltere, Cabo, Máquina, Peso Corporal, Smith
          "isUnilateral": false, // true se feito um lado de cada vez, false caso contrário
          "tempoDescansoSegundos": 90, // inteiro (tempo de descanso padrão em segundos)
          "volume": "4x10" // string contendo séries x repetições (ex: "4x10", "3x12", "4x12-10-8")
        }
      ]
    }
  ]
}

Regras Cruciais de Mapeamento:
1. **grupoMuscular**: Escolha rigorosamente um destes: [Peito, Costas, Ombro, Tríceps, Bíceps, Perna, Core, Glúteo].
   - "Elevação Lateral", "Desenvolvimento", "Crucifixo Invertido" e "Posterior de Ombro" devem ser mapeados como "Ombro".
   - "Abdominais" ou "Plancha" devem ser mapeados como "Core".
   - "Agachamento", "Leg Press", "Cadeira Extensora", "Mesa Flexora" e "Panturrilhas/Gêmeos" devem ser mapeados como "Perna".
   - "Elevação de Quadril" / "Glute Bridges" deve ser mapeado como "Glúteo".
2. **equipamento**: Escolha rigorosamente um destes exatos valores: [Livre, Barra, Haltere, Cabo, Máquina, Peso Corporal, Smith].
   - Se o texto indicar "Halteres" (plural) ou "Halter", mapeie obrigatoriamente como "Haltere" (no singular).
   - Se o texto indicar "Polia", "Crossover", "Pulley" ou similar, mapeie obrigatoriamente como "Cabo".
   - Se indicar "Máquina" ou "Polia/Máquina" (como Leg Press, Extensora, Flexora, Gêmeos em Pé na máquina), mapeie como "Máquina".
   - Exercícios com o próprio peso (Flexões de braço, Barra fixa, Abdominais no chão) devem ser "Peso Corporal".
3. **letra**: Comece no "A" e incremente em ordem alfabética ("A", "B", "C"...) para cada dia sequencial de treino.
4. **tipo**: Se a rotina tiver 3 dias, o tipo é "ABC". Se tiver 4 dias, "ABCD". Se tiver 5 dias, "ABCDE". Outros números de dias, coloque "CUSTOM".
5. **Saída**: Retorne APENAS o código JSON puro, sem textos explicativos, saudações ou formatação markdown, apenas o JSON bruto para que eu possa fazer o decode diretamente.
''';

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json; charset=utf-8',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': 'llama-3.1-8b-instant',
        'messages': [
          {'role': 'system', 'content': systemPrompt},
          {'role': 'user', 'content': rawText}
        ],
        'temperature': 0.1,
      }),
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(utf8.decode(response.bodyBytes));
      final content = responseData['choices'][0]['message']['content'] as String;
      
      String cleanJson = content.trim();
      if (cleanJson.startsWith('```')) {
        final lines = cleanJson.split('\n');
        if (lines.first.startsWith('```')) {
          lines.removeAt(0);
        }
        if (lines.last.startsWith('```')) {
          lines.removeLast();
        }
        cleanJson = lines.join('\n').trim();
      }
      return cleanJson;
    } else {
      throw Exception('Groq API Error (${response.statusCode}): ${response.body}');
    }
  }
}
