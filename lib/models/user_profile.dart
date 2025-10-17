class UserProfile {
  final int experiencePoints;
  final int level;
  final int streak;
  final int totalHabitsCompleted;
  final List<String> unlockedAchievements;
  final DateTime? lastUpdated;

  const UserProfile({
    required this.experiencePoints,
    required this.level,
    required this.streak,
    required this.totalHabitsCompleted,
    required this.unlockedAchievements,
    this.lastUpdated,
  });

  UserProfile copyWith({
    int? experiencePoints,
    int? level,
    int? streak,
    int? totalHabitsCompleted,
    List<String>? unlockedAchievements,
    DateTime? lastUpdated,
  }) {
    return UserProfile(
      experiencePoints: experiencePoints ?? this.experiencePoints,
      level: level ?? this.level,
      streak: streak ?? this.streak,
      totalHabitsCompleted: totalHabitsCompleted ?? this.totalHabitsCompleted,
      unlockedAchievements: unlockedAchievements ?? this.unlockedAchievements,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'experiencePoints': experiencePoints,
      'level': level,
      'streak': streak,
      'totalHabitsCompleted': totalHabitsCompleted,
      'unlockedAchievements': unlockedAchievements,
      'lastUpdated': lastUpdated?.toIso8601String(),
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      experiencePoints: json['experiencePoints'] ?? 0,
      level: json['level'] ?? 1,
      streak: json['streak'] ?? 0,
      totalHabitsCompleted: json['totalHabitsCompleted'] ?? 0,
      unlockedAchievements: List<String>.from(json['unlockedAchievements'] ?? []),
      lastUpdated: json['lastUpdated'] != null ? DateTime.parse(json['lastUpdated']) : null,
    );
  }

  // Calculate XP needed for next level
  int get xpForNextLevel {
    return (level * 100) - experiencePoints;
  }

  // Calculate total XP needed for current level
  int get xpForCurrentLevel {
    return (level - 1) * 100;
  }

  // Calculate progress percentage to next level
  double get levelProgress {
    final currentLevelXp = (level - 1) * 100;
    final nextLevelXp = level * 100;
    final progress = experiencePoints - currentLevelXp;
    final total = nextLevelXp - currentLevelXp;
    return progress / total;
  }
}
