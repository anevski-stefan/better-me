class Achievement {
  final String id;
  final String name;
  final String description;
  final String icon;
  final int xpReward;
  final String category;

  const Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.xpReward,
    required this.category,
  });

  static const List<Achievement> allAchievements = [
    Achievement(
      id: 'first_habit',
      name: 'First Steps',
      description: 'Complete your first habit',
      icon: '🎯',
      xpReward: 50,
      category: 'milestone',
    ),
    Achievement(
      id: 'streak_7',
      name: 'Week Warrior',
      description: 'Maintain a 7-day streak',
      icon: '🔥',
      xpReward: 100,
      category: 'streak',
    ),
    Achievement(
      id: 'streak_30',
      name: 'Streak Master',
      description: 'Maintain a 30-day streak',
      icon: '👑',
      xpReward: 500,
      category: 'streak',
    ),
    Achievement(
      id: 'system_builder',
      name: 'System Builder',
      description: 'Create 3 systems',
      icon: '🏗️',
      xpReward: 150,
      category: 'creation',
    ),
    Achievement(
      id: 'habit_hero',
      name: 'Habit Hero',
      description: 'Complete 100 habits',
      icon: '🦸',
      xpReward: 300,
      category: 'completion',
    ),
    Achievement(
      id: 'perfect_day',
      name: 'Perfect Day',
      description: 'Complete all habits in one day',
      icon: '⭐',
      xpReward: 200,
      category: 'perfection',
    ),
    Achievement(
      id: 'early_bird',
      name: 'Early Bird',
      description: 'Complete a morning habit',
      icon: '🌅',
      xpReward: 75,
      category: 'timing',
    ),
    Achievement(
      id: 'night_owl',
      name: 'Night Owl',
      description: 'Complete an evening habit',
      icon: '🦉',
      xpReward: 75,
      category: 'timing',
    ),
  ];

  static Achievement? getById(String id) {
    try {
      return allAchievements.firstWhere((achievement) => achievement.id == id);
    } catch (e) {
      return null;
    }
  }
}
