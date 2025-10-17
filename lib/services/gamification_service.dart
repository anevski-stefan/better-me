import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';
import '../models/achievement.dart';

class GamificationService {
  static const String _profileKey = 'user_profile';
  static final GamificationService _instance = GamificationService._internal();
  factory GamificationService() => _instance;
  GamificationService._internal();

  UserProfile? _currentProfile;

  Future<UserProfile> getProfile() async {
    if (_currentProfile != null) return _currentProfile!;

    final prefs = await SharedPreferences.getInstance();
    final profileJson = prefs.getString(_profileKey);

    if (profileJson != null) {
      _currentProfile = UserProfile.fromJson(jsonDecode(profileJson));
    } else {
      _currentProfile = const UserProfile(
        experiencePoints: 0,
        level: 1,
        streak: 0,
        totalHabitsCompleted: 0,
        unlockedAchievements: [],
        lastUpdated: null,
      );
      await _saveProfile();
    }

    return _currentProfile!;
  }

  Future<void> _saveProfile() async {
    if (_currentProfile == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileKey, jsonEncode(_currentProfile!.toJson()));
  }

  Future<void> completeHabit() async {
    final profile = await getProfile();
    final newXp = profile.experiencePoints + 10;
    final newTotal = profile.totalHabitsCompleted + 1;
    
    // Calculate new level
    final newLevel = _calculateLevel(newXp);
    
    // Check for achievements
    final newAchievements = await _checkAchievements(profile, newTotal, newLevel);
    
    _currentProfile = profile.copyWith(
      experiencePoints: newXp,
      level: newLevel,
      totalHabitsCompleted: newTotal,
      unlockedAchievements: newAchievements,
      lastUpdated: DateTime.now(),
    );

    await _saveProfile();
  }

  Future<void> completeAllHabitsInDay() async {
    final profile = await getProfile();
    final newXp = profile.experiencePoints + 50;
    final newLevel = _calculateLevel(newXp);
    
    final newAchievements = await _checkAchievements(profile, profile.totalHabitsCompleted, newLevel);
    
    _currentProfile = profile.copyWith(
      experiencePoints: newXp,
      level: newLevel,
      unlockedAchievements: newAchievements,
      lastUpdated: DateTime.now(),
    );

    await _saveProfile();
  }

  Future<void> updateStreak(int newStreak) async {
    final profile = await getProfile();
    final newAchievements = await _checkAchievements(profile, profile.totalHabitsCompleted, profile.level);
    
    _currentProfile = profile.copyWith(
      streak: newStreak,
      unlockedAchievements: newAchievements,
      lastUpdated: DateTime.now(),
    );

    await _saveProfile();
  }

  Future<void> createSystem() async {
    final profile = await getProfile();
    final newXp = profile.experiencePoints + 25;
    final newLevel = _calculateLevel(newXp);
    
    final newAchievements = await _checkAchievements(profile, profile.totalHabitsCompleted, newLevel);
    
    _currentProfile = profile.copyWith(
      experiencePoints: newXp,
      level: newLevel,
      unlockedAchievements: newAchievements,
      lastUpdated: DateTime.now(),
    );

    await _saveProfile();
  }

  Future<void> createGoal() async {
    final profile = await getProfile();
    final newXp = profile.experiencePoints + 25; // Creating goals gives XP
    final newLevel = _calculateLevel(newXp);

    final newAchievements = await _checkAchievements(profile, profile.totalHabitsCompleted, newLevel);

    _currentProfile = profile.copyWith(
      experiencePoints: newXp,
      level: newLevel,
      unlockedAchievements: newAchievements,
      lastUpdated: DateTime.now(),
    );

    await _saveProfile();
  }

  Future<void> completeGoal() async {
    final profile = await getProfile();
    final newXp = profile.experiencePoints + 100; // Goals give more XP
    final newLevel = _calculateLevel(newXp);

    final newAchievements = await _checkAchievements(profile, profile.totalHabitsCompleted, newLevel);

    _currentProfile = profile.copyWith(
      experiencePoints: newXp,
      level: newLevel,
      unlockedAchievements: newAchievements,
      lastUpdated: DateTime.now(),
    );

    await _saveProfile();
  }

  int _calculateLevel(int xp) {
    return (xp ~/ 100) + 1;
  }

  Future<List<String>> _checkAchievements(UserProfile profile, int totalHabits, int level) async {
    final currentAchievements = List<String>.from(profile.unlockedAchievements);
    final newAchievements = <String>[];

    // Check for new achievements
    for (final achievement in Achievement.allAchievements) {
      if (currentAchievements.contains(achievement.id)) continue;

      bool shouldUnlock = false;

      switch (achievement.id) {
        case 'first_habit':
          shouldUnlock = totalHabits >= 1;
          break;
        case 'streak_7':
          shouldUnlock = profile.streak >= 7;
          break;
        case 'streak_30':
          shouldUnlock = profile.streak >= 30;
          break;
        case 'system_builder':
          // This would need to be tracked separately
          break;
        case 'habit_hero':
          shouldUnlock = totalHabits >= 100;
          break;
        case 'perfect_day':
          // This would need to be tracked separately
          break;
        case 'early_bird':
        case 'night_owl':
          // These would need time-based tracking
          break;
      }

      if (shouldUnlock) {
        currentAchievements.add(achievement.id);
        newAchievements.add(achievement.id);
      }
    }

    return currentAchievements;
  }

  Future<List<Achievement>> getUnlockedAchievements() async {
    final profile = await getProfile();
    return profile.unlockedAchievements
        .map((id) => Achievement.getById(id))
        .where((achievement) => achievement != null)
        .cast<Achievement>()
        .toList();
  }

  Future<void> resetProfile() async {
    _currentProfile = const UserProfile(
      experiencePoints: 0,
      level: 1,
      streak: 0,
      totalHabitsCompleted: 0,
      unlockedAchievements: [],
      lastUpdated: null,
    );
    await _saveProfile();
  }
}
