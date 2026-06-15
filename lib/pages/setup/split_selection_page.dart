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
                      'Mete Marcha',
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
                Text(
                  'Selecione uma divisão abaixo para adicioná-la à sua lista de treinos ativos.',
                  style: TextStyle(
                    color: context.onSurface,
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
                      assetPath: 'assets/images/workout_abc.webp',
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
                      assetPath: 'assets/images/workout_abcd.webp',
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
                      assetPath: 'assets/images/workout_abcde.webp',
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
                      assetPath: 'assets/images/workout_custom.webp',
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
              Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Toque para ver os detalhes',
                        style: TextStyle(color: context.onSurface, fontSize: 13),
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
    required String assetPath,
    required String desc,
    required List<String> daysInfo,
  }) {
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      color: context.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: context.divider, width: 1),
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
          assetPath: assetPath,
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
                style: TextStyle(
                  color: context.onSurface,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              // Imagem no centro
              _buildWorkoutCardImage(assetPath),
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
    required String assetPath,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.cardColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Imagem do Treino como Banner
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    assetPath,
                    width: double.infinity,
                    height: 120,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 16),
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
                          style: TextStyle(color: context.onSurface, fontSize: 13),
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
                          style: TextStyle(color: context.onBackground, fontSize: 13),
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
      ),
    );
  }

  // ─── DESENHO DOS ÍCONES CUSTOMIZADOS ──────────────────────────────────────────

  Widget _buildWorkoutCardImage(String assetPath) {
    return Container(
      height: 70,
      width: double.infinity,
      decoration: const BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset(
          assetPath,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  void _showImportJsonDialog(BuildContext context, WidgetRef ref) {
    final textCtrl = TextEditingController();
    final rawTextCtrl = TextEditingController();
    bool clearUnused = true;
    bool isAiView = false;
    bool isLoading = false;
    String errorMessage = '';

    showDialog(
      context: context,
      barrierDismissible: !isLoading,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Icon(
                  isAiView ? Icons.psychology_rounded : Icons.code_rounded,
                  color: isAiView ? AppColors.primaryLight : AppColors.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isAiView ? 'Formatar Treino com IA' : 'Importar Treino (JSON)',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: MediaQuery.of(context).size.width * 0.9,
              child: SingleChildScrollView(
                child: AnimatedCrossFade(
                  duration: const Duration(milliseconds: 250),
                  crossFadeState: isAiView ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                  firstChild: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: context.cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: context.divider),
                        ),
                        child: Text(
                          'Cole o código JSON do seu treino abaixo. Se tiver apenas o texto simples (ex: do WhatsApp), clique em "Formatar com IA" no botão abaixo para organizá-lo automaticamente.',
                          style: TextStyle(fontSize: 12, color: context.onSurface, height: 1.4),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          if (groqBeta) ...[
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  setState(() {
                                    isAiView = true;
                                    errorMessage = '';
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                                  foregroundColor: AppColors.primaryLight,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                icon: const Icon(Icons.psychology_rounded, size: 18),
                                label: const Text(
                                  'Formatar com IA',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                          ],
                          Expanded(
                            child: OutlinedButton.icon(
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
                                    '          "volume": "4x10",\n'
                                    '          "observacoes": "Dicas de biomecânica ou detalhes adicionais da execução do exercício (ex: Pegada pronada...)" // Pode ser nulo se não houver observações\n'
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
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                side: BorderSide(color: context.divider),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              icon: Icon(Icons.copy_all_rounded, size: 16, color: context.onSurface),
                              label: Text(
                                'Copiar Prompt',
                                style: TextStyle(fontSize: 12, color: context.onSurface),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: textCtrl,
                        maxLines: 8,
                        style: TextStyle(fontFamily: 'monospace', fontSize: 11, color: context.onBackground),
                        decoration: InputDecoration(
                          hintText: 'Cole o código JSON aqui...',
                          alignLabelWithHint: true,
                          contentPadding: const EdgeInsets.all(12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: context.divider),
                          ),
                          filled: true,
                          fillColor: context.cardColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: () {
                          setState(() {
                            clearUnused = !clearUnused;
                          });
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                          child: Row(
                            children: [
                              SizedBox(
                                height: 20,
                                width: 20,
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
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Limpar biblioteca (remove exercícios padrão não utilizados)',
                                  style: TextStyle(fontSize: 11, color: context.onSurface),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  secondChild: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Cole o texto bruto do treino (WhatsApp, Notas, etc.). A IA estruturará tudo no formato correto para o aplicativo de forma automática.',
                        style: TextStyle(fontSize: 12, color: context.onSurface, height: 1.4),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: rawTextCtrl,
                        maxLines: 6,
                        enabled: !isLoading,
                        decoration: InputDecoration(
                          hintText: 'Ex:\nTreino A - Peito e Tríceps\n- Supino reto com halteres 4 séries de 10 reps\n- Tríceps corda 3x12 descansa 1 min...',
                          alignLabelWithHint: true,
                          contentPadding: const EdgeInsets.all(12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: context.divider),
                          ),
                          filled: true,
                          fillColor: context.cardColor,
                        ),
                      ),
                      if (errorMessage.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  errorMessage,
                                  style: const TextStyle(color: Colors.redAccent, fontSize: 11, height: 1.3),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: isLoading
                                ? null
                                : () {
                                    setState(() {
                                      isAiView = false;
                                      errorMessage = '';
                                    });
                                  },
                            child: const Text('Voltar'),
                          ),
                          const SizedBox(width: 8),
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
                                      final prefs = await SharedPreferences.getInstance();
                                      final apiKey = prefs.getString('groq_api_key') ??
                                          ('gsk_0U02Xmja'
                                              '1UEmgIbrgdUkWGdyb3FYQUYZfpEQGVx0CSYa9Hz0RHIS');

                                      final jsonResult = await _processWorkoutWithGroq(rawText, apiKey);

                                      textCtrl.text = jsonResult;

                                      setState(() {
                                        isLoading = false;
                                        isAiView = false;
                                        errorMessage = '';
                                      });

                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Treino formatado com sucesso! ✓'),
                                        ),
                                      );
                                    } catch (e) {
                                      String errorMsg =
                                          'Ocorreu um erro ao formatar com IA. Verifique o texto e tente novamente.';
                                      final errStr = e.toString();
                                      if (errStr.contains('SocketException') ||
                                          errStr.contains('Failed host lookup') ||
                                          errStr.contains('Network') ||
                                          errStr.contains('errno = 7')) {
                                        errorMsg = 'Sem conexão com a internet. Verifique sua rede e tente novamente.';
                                      } else if (errStr.contains('rate_limit') ||
                                          errStr.contains('rate limit') ||
                                          errStr.contains('Rate limit') ||
                                          errStr.contains('429') ||
                                          errStr.contains('413') ||
                                          errStr.contains('Limit 6000') ||
                                          errStr.contains('limit_exceeded')) {
                                        errorMsg =
                                            'O limite temporário de requisições da IA foi atingido. Por favor, aguarde 1 minuto e tente novamente.';
                                      } else if (errStr.contains('invalid_api_key') ||
                                          errStr.contains('401') ||
                                          errStr.contains('Unauthorized')) {
                                        errorMsg =
                                            'A chave de API da IA está inválida ou expirada. Verifique as configurações.';
                                      }
                                      setState(() {
                                        isLoading = false;
                                        errorMessage = errorMsg;
                                      });
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: isLoading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white),
                                  )
                                : const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.auto_awesome_rounded, size: 14),
                                      SizedBox(width: 6),
                                      Text('Formatar Treino'),
                                    ],
                                  ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: isAiView
                ? []
                : [
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
                            throw const FormatException('O campo "dias" deve ser uma lista.');
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

                            final allExercises = await ref.read(exerciseDaoProvider).getAll();

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
                                  if (e.nome.trim().toLowerCase() == normalizedSearchName) {
                                    foundEx = e;
                                    break;
                                  }
                                }

                                int exId;
                                if (foundEx != null) {
                                  exId = foundEx.id;
                                  final jsonObs = exObj['observacoes']?.toString().trim();
                                  if (jsonObs != null &&
                                      jsonObs.isNotEmpty &&
                                      (foundEx.observacoes == null ||
                                          foundEx.observacoes!.isEmpty)) {
                                    await ref.read(exerciseDaoProvider).updateExercise(
                                          foundEx.copyWith(
                                            observacoes: Value(jsonObs),
                                          ),
                                        );
                                  }
                                } else {
                                  exId = await ref.read(exerciseDaoProvider).insertExercise(
                                        ExercisesCompanion.insert(
                                          nome: exName,
                                          grupoMuscular:
                                              exObj['grupoMuscular']?.toString() ?? 'Peito',
                                          equipamento: Value(
                                              exObj['equipamento']?.toString() ?? 'Livre'),
                                          isUnilateral: Value(
                                              exObj['isUnilateral'] as bool? ?? false),
                                          tempoDescansoSegundos: Value(
                                              exObj['tempoDescansoSegundos'] as int? ?? 90),
                                          volume: Value(exObj['volume']?.toString()),
                                          link: Value(exObj['link']?.toString()),
                                          observacoes: Value(exObj['observacoes']?.toString()),
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
                                backgroundColor: context.cardColor,
                                title: const Text('Erro na Importação'),
                                content:
                                    Text('Não foi possível importar o treino. Detalhes:\n$e'),
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
          );
        },
      ),
    );
  }

  Future<String> _processWorkoutWithGroq(String rawText, String apiKey) async {
    final url = Uri.parse('https://api.groq.com/openai/v1/chat/completions');
    
    const systemPrompt = '''
Converta o texto de treino em um objeto JSON válido seguindo esta estrutura:
{
  "nome": "Nome do Treino",
  "tipo": "ABC", // "ABC", "ABCD", "ABCDE" ou "CUSTOM"
  "dias": [
    {
      "letra": "A", // "A", "B", "C", "D", "E" sequencialmente
      "nome": "Nome do Dia",
      "exercicios": [
        {
          "nome": "Nome do Exercício",
          "grupoMuscular": "Peito", // Peito, Costas, Ombro, Tríceps, Bíceps, Perna, Core, Glúteo
          "equipamento": "Barra", // Livre, Barra, Haltere, Cabo, Máquina, Peso Corporal, Smith
          "isUnilateral": false,
          "tempoDescansoSegundos": 90,
          "volume": "4x10", // séries x repetições
          "observacoes": "Instruções específicas, biomecânica ou dicas de execução" // ou null
        }
      ]
    }
  ]
}

Regras:
1. grupoMuscular deve ser exatamente um destes: [Peito, Costas, Ombro, Tríceps, Bíceps, Perna, Core, Glúteo]. Mapeie Elevação Lateral/Crucifixo Invertido/Posterior de Ombro como "Ombro"; Abdominais como "Core"; Agachamento/Leg Press/Extensora/Flexora/Panturrilha como "Perna"; Elevação de Quadril como "Glúteo".
2. equipamento deve ser exatamente um destes: [Livre, Barra, Haltere, Cabo, Máquina, Peso Corporal, Smith]. Mapeie "Halteres" como "Haltere"; "Polia/Crossover/Pulley" como "Cabo"; Leg Press/Extensora/Flexora/Hack/Gêmeos na máquina como "Máquina"; Flexão/Barra Fixa/Abdominais como "Peso Corporal".
3. letra começa em "A" e segue sequencialmente.
4. tipo: 3 dias = "ABC", 4 dias = "ABCD", 5 dias = "ABCDE", outro = "CUSTOM".
5. observacoes: extraia detalhes, biomecânica ou observações do texto original para este campo.
6. Retorne APENAS o código JSON bruto sem markdown ou textos explicativos.
''';

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json; charset=utf-8',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': 'llama-3.3-70b-versatile',
        'messages': [
          {'role': 'system', 'content': systemPrompt},
          {'role': 'user', 'content': rawText}
        ],
        'temperature': 0.1,
        'max_tokens': 4000,
        'response_format': {'type': 'json_object'},
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
