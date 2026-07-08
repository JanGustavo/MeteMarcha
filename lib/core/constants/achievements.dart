// lib/core/constants/achievements.dart

class AchievementLevel {
  final String name; // Bronze, Prata, Ouro
  final double value;
  final String icon;

  const AchievementLevel({
    required this.name,
    required this.value,
    required this.icon,
  });
}

enum AchievementType {
  exercise1rm,
  exerciseSetsCount,
  totalWorkouts,
  weekStreak,
  totalVolumeTons,
}

class Achievement {
  final String id;
  final String title;
  final String shortTitle;
  final String description;
  final AchievementType type;
  final List<String>? keywords;
  final List<AchievementLevel> levels;
  final String emoji;

  const Achievement({
    required this.id,
    required this.title,
    required this.shortTitle,
    required this.description,
    required this.type,
    this.keywords,
    required this.levels,
    required this.emoji,
  });
}

const List<Achievement> achievements = [
  Achievement(
    id: 'bench_press',
    title: 'Monstro do Supino',
    shortTitle: 'Supino',
    description: 'Força máxima estimada no supino',
    type: AchievementType.exercise1rm,
    keywords: ['supino'],
    emoji: '🏋️‍♂️',
    levels: [
      AchievementLevel(name: 'Bronze', value: 60.0, icon: '🥉'),
      AchievementLevel(name: 'Prata', value: 100.0, icon: '🥈'),
      AchievementLevel(name: 'Ouro', value: 140.0, icon: '🥇'),
    ],
  ),
  Achievement(
    id: 'squat',
    title: 'Rei do Agachamento',
    shortTitle: 'Agachamento',
    description: 'Força máxima estimada no agachamento',
    type: AchievementType.exercise1rm,
    keywords: ['agachamento'],
    emoji: '🦵',
    levels: [
      AchievementLevel(name: 'Bronze', value: 80.0, icon: '🥉'),
      AchievementLevel(name: 'Prata', value: 120.0, icon: '🥈'),
      AchievementLevel(name: 'Ouro', value: 160.0, icon: '🥇'),
    ],
  ),
  Achievement(
    id: 'deadlift',
    title: 'Mestre do Terra',
    shortTitle: 'Terra',
    description: 'Força máxima estimada no terra',
    type: AchievementType.exercise1rm,
    keywords: ['terra'],
    emoji: '💀',
    levels: [
      AchievementLevel(name: 'Bronze', value: 100.0, icon: '🥉'),
      AchievementLevel(name: 'Prata', value: 150.0, icon: '🥈'),
      AchievementLevel(name: 'Ouro', value: 200.0, icon: '🥇'),
    ],
  ),
  Achievement(
    id: 'biceps',
    title: 'Levantando o Mundo',
    shortTitle: 'Bíceps',
    description: 'Força máxima estimada em roscas/bíceps',
    type: AchievementType.exercise1rm,
    keywords: ['rosca', 'biceps', 'bíceps'],
    emoji: '💪',
    levels: [
      AchievementLevel(name: 'Bronze', value: 20.0, icon: '🥉'),
      AchievementLevel(name: 'Prata', value: 40.0, icon: '🥈'),
      AchievementLevel(name: 'Ouro', value: 60.0, icon: '🥇'),
    ],
  ),
  Achievement(
    id: 'back',
    title: 'Mais Largo que a Porta',
    shortTitle: 'Costas',
    description: 'Força máxima estimada em puxadas/remadas',
    type: AchievementType.exercise1rm,
    keywords: ['puxada', 'remada', 'barra fixa', 'pulldown'],
    emoji: '🚪',
    levels: [
      AchievementLevel(name: 'Bronze', value: 60.0, icon: '🥉'),
      AchievementLevel(name: 'Prata', value: 90.0, icon: '🥈'),
      AchievementLevel(name: 'Ouro', value: 120.0, icon: '🥇'),
    ],
  ),
  Achievement(
    id: 'calves',
    title: 'No Sapatinho',
    shortTitle: 'Panturrilha',
    description: 'Força máxima estimada na panturrilha',
    type: AchievementType.exercise1rm,
    keywords: ['panturrilha', 'gemeos', 'gêmeos'],
    emoji: '👟',
    levels: [
      AchievementLevel(name: 'Bronze', value: 45.0, icon: '🥉'),
      AchievementLevel(name: 'Prata', value: 80.0, icon: '🥈'),
      AchievementLevel(name: 'Ouro', value: 120.0, icon: '🥇'),
    ],
  ),
  Achievement(
    id: 'abs',
    title: 'É pra Trincar',
    shortTitle: 'Abdômen',
    description: 'Total de séries de abdômen concluídas',
    type: AchievementType.exerciseSetsCount,
    keywords: ['abdominal', 'infra', 'supra', 'prancha'],
    emoji: '🍫',
    levels: [
      AchievementLevel(name: 'Bronze', value: 30.0, icon: '🥉'),
      AchievementLevel(name: 'Prata', value: 100.0, icon: '🥈'),
      AchievementLevel(name: 'Ouro', value: 250.0, icon: '🥇'),
    ],
  ),
  Achievement(
    id: 'workouts_count',
    title: 'Consistência de Aço',
    shortTitle: 'Treinos',
    description: 'Complete sessões de treino',
    type: AchievementType.totalWorkouts,
    emoji: '🔥',
    levels: [
      AchievementLevel(name: 'Bronze', value: 10.0, icon: '🥉'),
      AchievementLevel(name: 'Prata', value: 50.0, icon: '🥈'),
      AchievementLevel(name: 'Ouro', value: 100.0, icon: '🥇'),
    ],
  ),
  Achievement(
    id: 'week_streak',
    title: 'Foco Inabalável',
    shortTitle: 'Semanas',
    description: 'Mantenha semanas ativas consecutivas',
    type: AchievementType.weekStreak,
    emoji: '⚡',
    levels: [
      AchievementLevel(name: 'Bronze', value: 3.0, icon: '🥉'),
      AchievementLevel(name: 'Prata', value: 6.0, icon: '🥈'),
      AchievementLevel(name: 'Ouro', value: 12.0, icon: '🥇'),
    ],
  ),
  Achievement(
    id: 'total_volume',
    title: 'Trator Humano',
    shortTitle: 'Volume',
    description: 'Volume total acumulado em toneladas',
    type: AchievementType.totalVolumeTons,
    emoji: '🚜',
    levels: [
      AchievementLevel(name: 'Bronze', value: 10.0, icon: '🥉'),
      AchievementLevel(name: 'Prata', value: 50.0, icon: '🥈'),
      AchievementLevel(name: 'Ouro', value: 200.0, icon: '🥇'),
    ],
  ),
];
