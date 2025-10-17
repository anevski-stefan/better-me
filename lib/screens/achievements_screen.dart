import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../models/achievement.dart';
import '../models/user_profile.dart';
import '../services/gamification_service.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  final GamificationService _gamificationService = GamificationService();
  UserProfile? _userProfile;
  List<Achievement> _unlockedAchievements = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final profile = await _gamificationService.getProfile();
    final unlocked = await _gamificationService.getUnlockedAchievements();
    
    setState(() {
      _userProfile = profile;
      _unlockedAchievements = unlocked;
    });
  }

  bool _isAchievementUnlocked(String achievementId) {
    return _unlockedAchievements.any((achievement) => achievement.id == achievementId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Achievements',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress Overview
            if (_userProfile != null)
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Icon(
                        Iconsax.crown_1,
                        color: Theme.of(context).colorScheme.primary,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Achievement Progress',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${_unlockedAchievements.length} of ${Achievement.allAchievements.length} unlocked',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).textTheme.bodySmall?.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${((_unlockedAchievements.length / Achievement.allAchievements.length) * 100).toInt()}%',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Achievements Grid
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: Achievement.allAchievements.length,
                itemBuilder: (context, index) {
                  final achievement = Achievement.allAchievements[index];
                  final isUnlocked = _isAchievementUnlocked(achievement.id);
                  
                  return Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isUnlocked 
                            ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
                            : Theme.of(context).dividerColor.withOpacity(0.1),
                        width: isUnlocked ? 2 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Achievement Icon
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: isUnlocked 
                                  ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                                  : Theme.of(context).colorScheme.primary.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: Center(
                              child: Text(
                                achievement.icon,
                                style: TextStyle(
                                  fontSize: 24,
                                  color: isUnlocked 
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context).textTheme.bodySmall?.color,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          
                          // Achievement Name
                          Text(
                            achievement.name,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isUnlocked 
                                  ? Theme.of(context).textTheme.titleMedium?.color
                                  : Theme.of(context).textTheme.bodySmall?.color,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          
                          // Achievement Description
                          Text(
                            achievement.description,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).textTheme.bodySmall?.color,
                              fontSize: 11,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          
                          // XP Reward
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: isUnlocked 
                                  ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                                  : Theme.of(context).colorScheme.primary.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '+${achievement.xpReward} XP',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: 10,
                                color: isUnlocked 
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).textTheme.bodySmall?.color,
                              ),
                            ),
                          ),
                          
                          // Unlocked Badge
                          if (isUnlocked)
                            Container(
                              margin: const EdgeInsets.only(top: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Iconsax.tick_circle,
                                    color: Colors.white,
                                    size: 10,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    'Unlocked',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
