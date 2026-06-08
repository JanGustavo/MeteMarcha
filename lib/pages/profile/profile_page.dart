// lib/pages/profile/profile_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/app_database.dart';
import '../../core/providers/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/week_utils.dart';

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
    }

    setState(() => _saving = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil atualizado ✓')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);
    final weeklyWeightsAsync = ref.watch(weeklyWeightsProvider);

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

          // ── Form ────────────────────────────────────────────
          SliverToBoxAdapter(
            child: profileAsync.when(
              data: (profile) {
                _populate(profile);
                return Card(
                  margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // Avatar / ícone
                        CircleAvatar(
                          radius: 36,
                          backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                          child: const Icon(
                            Icons.person_rounded,
                            size: 36,
                            color: AppColors.primary,
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
                        ),
                        const SizedBox(height: 12),

                        // Altura + Peso
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _alturaCtrl,
                                keyboardType: TextInputType.number,
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
                return const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Text(
                      'Nenhum peso registrado ainda.',
                      style: TextStyle(color: AppColors.onSurface),
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
              : AppColors.divider,
        ),
      ),
      child: ListTile(
        leading: Icon(
          Icons.monitor_weight_rounded,
          color: isCurrentWeek ? AppColors.primary : AppColors.onSurface,
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
          style: const TextStyle(color: AppColors.onSurface, fontSize: 12),
        ),
      ),
    );
  }
}
