// lib/pages/cardio/cardio_guide_page.dart

import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class CardioGuidePage extends StatelessWidget {
  const CardioGuidePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Guia de Cárdio 📖'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Qual cárdio fazer e com qual frequência?',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: context.onBackground,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Escolha o estímulo ideal com base no seu objetivo principal. Equilibrar o cárdio com o treino de força melhora sua recuperação e acelera seus resultados.',
            style: TextStyle(
              fontSize: 14,
              color: context.onSurface,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),

          // LISS Card
          _buildGuideCard(
            context,
            title: '1. Emagrecimento & Queima de Gordura (LISS)',
            subtitle: 'Low Intensity Steady State (Cárdio de Baixa Intensidade)',
            description: 'Mantém o batimento cardíaco constante em uma faixa de queima de gordura (60-70% da FCM). Utiliza principalmente gordura como fonte de energia.',
            frequency: '3 a 5 vezes por semana',
            duration: '30 a 60 minutos',
            types: 'Caminhada rápida na esteira com inclinação, bicicleta em ritmo moderado.',
            gradientColors: [Colors.amber.shade700, Colors.orangeAccent.shade400],
            icon: Icons.directions_walk_rounded,
          ),

          const SizedBox(height: 16),

          // HIIT Card
          _buildGuideCard(
            context,
            title: '2. Resistência & Condicionamento (HIIT)',
            subtitle: 'High Intensity Interval Training (Treino Intervalado de Alta Intensidade)',
            description: 'Alterna tiros de esforço máximo (90% FCM) com períodos de descanso ativo (50% FCM). Acelera o metabolismo e promove queima calórica pós-treino (EPOC).',
            frequency: '2 a 3 vezes por semana',
            duration: '15 a 25 minutos',
            types: 'Simulador de escada, tiros rápidos na esteira ou tiros na bicicleta.',
            gradientColors: [Colors.red.shade700, Colors.deepOrangeAccent.shade400],
            icon: Icons.bolt_rounded,
          ),

          const SizedBox(height: 16),

          // Recovery Card
          _buildGuideCard(
            context,
            title: '3. Hipertrofia & Saúde Cardíaca (Regenerativo)',
            subtitle: 'Cárdio de Recuperação Ativa',
            description: 'Melhora a circulação sanguínea, auxiliando no transporte de nutrientes aos músculos e na remoção de metabólitos, sem sobrecarregar as articulações ou prejudicar os treinos de força.',
            frequency: '2 a 3 vezes por semana',
            duration: '20 a 30 minutos',
            types: 'Elíptico (baixo impacto) ou bicicleta ergométrica horizontal.',
            gradientColors: [Colors.teal.shade700, Colors.cyanAccent.shade400],
            icon: Icons.favorite_rounded,
          ),
          
          const SizedBox(height: 24),
          
          // FCM Formula Box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.divider.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.divider.withValues(alpha: 0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, color: AppColors.primaryLight, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Como calcular sua FCM?',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: context.onBackground,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'A Frequência Cardíaca Máxima (FCM) estimada pode ser calculada com a fórmula:\n\nFCM = 220 - Sua Idade\n\nPor exemplo, se você tem 25 anos:\nFCM = 195 bpm.\n* Faixa LISS (60-70%): 117 a 136 bpm.\n* Faixa HIIT (90%): tiros próximos a 175 bpm.',
                  style: TextStyle(
                    fontSize: 12,
                    color: context.onSurface,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuideCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String description,
    required String frequency,
    required String duration,
    required String types,
    required List<Color> gradientColors,
    required IconData icon,
  }) {
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: context.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: context.onBackground,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 12),
                _buildInfoRow(context, 'Frequência:', frequency),
                const SizedBox(height: 6),
                _buildInfoRow(context, 'Duração:', duration),
                const SizedBox(height: 6),
                _buildInfoRow(context, 'Opções:', types),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: context.onSurface,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12,
              color: context.onBackground,
            ),
          ),
        ),
      ],
    );
  }
}
