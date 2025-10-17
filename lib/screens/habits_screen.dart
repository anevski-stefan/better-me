import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../models/system.dart';
import '../models/habit.dart';
import '../services/data_service.dart';
import 'habit_detail_screen.dart';

class HabitsScreen extends StatefulWidget {
  const HabitsScreen({super.key});

  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen> {
  final DataService _dataService = DataService();
  List<System> _systems = [];

  @override
  void initState() {
    super.initState();
    _loadSystems();
  }

  Future<void> _loadSystems() async {
    final systems = await _dataService.getSystems();
    setState(() {
      _systems = systems;
    });
  }

  List<Habit> _getAllHabits() {
    final allHabits = <Habit>[];
    for (final system in _systems) {
      allHabits.addAll(system.habits);
    }
    return allHabits;
  }

  Future<void> _toggleHabit(Habit habit) async {
    final system = _systems.firstWhere((s) => s.habits.contains(habit));
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    List<DateTime> newCompletedDates = List.from(habit.completedDates ?? []);
    
    if (habit.isCompleted) {
      // If habit is currently completed, remove today from completedDates
      newCompletedDates.removeWhere((completedDate) =>
          completedDate.year == today.year &&
          completedDate.month == today.month &&
          completedDate.day == today.day);
    } else {
      // If habit is not completed, add today to completedDates
      newCompletedDates.add(today);
    }
    
    final updatedHabit = habit.copyWith(
      isCompleted: !habit.isCompleted,
      completedAt: habit.isCompleted ? null : now,
      completedDates: newCompletedDates,
    );
    
    await _dataService.updateHabitInSystem(system.id, updatedHabit);
    _loadSystems();
  }

  @override
  Widget build(BuildContext context) {
    final allHabits = _getAllHabits();
    final completedHabits = allHabits.where((h) => h.isCompleted).length;
    final totalHabits = allHabits.length;
    final progressPercentage = totalHabits > 0 ? completedHabits / totalHabits : 0.0;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'All Habits',
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
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: allHabits.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Iconsax.tick_circle,
                        size: 64,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'No Habits Yet',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Create systems and add habits to get started',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                children: [
                  // Progress Overview
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
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
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Today\'s Progress',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '$completedHabits of $totalHabits habits completed',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).textTheme.bodySmall?.color,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${(progressPercentage * 100).toInt()}%',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Habits List Grouped by System
                  Expanded(
                    child: ListView.builder(
                      itemCount: _systems.length,
                      itemBuilder: (context, systemIndex) {
                        final system = _systems[systemIndex];
                        if (system.habits.isEmpty) return const SizedBox.shrink();
                        
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // System Header
                            Padding(
                              padding: EdgeInsets.only(
                                left: 4, 
                                bottom: 8, 
                                top: systemIndex > 0 ? 24 : 0
                              ),
                              child: Text(
                                system.name,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                            // Habits for this system
                            ...system.habits.map((habit) {
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(16),
                                    onTap: () async {
                                      final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => HabitDetailScreen(
                                            habit: habit,
                                            system: system,
                                          ),
                                        ),
                                      );
                                      // Always reload systems when returning from detail screen
                                      _loadSystems();
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).cardColor,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: Theme.of(context).dividerColor.withOpacity(0.1),
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.05),
                                            blurRadius: 10,
                                            offset: const Offset(0, 5),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        children: [
                                          GestureDetector(
                                            onTap: () => _toggleHabit(habit),
                                            child: Container(
                                              width: 24,
                                              height: 24,
                                              decoration: BoxDecoration(
                                                color: habit.isCompleted
                                                    ? Theme.of(context).colorScheme.primary
                                                    : Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(6),
                                                border: habit.isCompleted
                                                    ? null
                                                    : Border.all(
                                                        color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                                                        width: 2,
                                                      ),
                                              ),
                                              child: habit.isCompleted
                                                  ? const Icon(
                                                      Iconsax.tick_circle,
                                                      color: Colors.white,
                                                      size: 16,
                                                    )
                                                  : null,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  habit.name,
                                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                    decoration: habit.isCompleted
                                                        ? TextDecoration.lineThrough
                                                        : null,
                                                    color: habit.isCompleted
                                                        ? Theme.of(context).textTheme.bodySmall?.color
                                                        : null,
                                                  ),
                                                ),
                                                if (habit.description.isNotEmpty) ...[
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    habit.description,
                                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                      color: Theme.of(context).textTheme.bodySmall?.color,
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                          if (habit.isCompleted)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                'Done',
                                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                  color: Theme.of(context).colorScheme.primary,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
        ),
      ),
    );
  }
}