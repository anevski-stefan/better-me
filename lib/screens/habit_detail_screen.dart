import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../models/habit.dart';
import '../models/system.dart';
import '../services/data_service.dart';
import '../services/gamification_service.dart';
import '../services/notification_service.dart';
import 'add_habit_screen.dart';

class HabitDetailScreen extends StatefulWidget {
  final Habit habit;
  final System system;

  const HabitDetailScreen({
    super.key,
    required this.habit,
    required this.system,
  });

  @override
  State<HabitDetailScreen> createState() => _HabitDetailScreenState();
}

class _HabitDetailScreenState extends State<HabitDetailScreen> {
  final DataService _dataService = DataService();
  final GamificationService _gamificationService = GamificationService();
  late Habit _currentHabit;
  late System _currentSystem;

  @override
  void initState() {
    super.initState();
    _currentHabit = widget.habit;
    _currentSystem = widget.system;
  }

  Future<void> _loadHabit() async {
    final systems = await _dataService.getSystems();
    try {
      final system = systems.firstWhere((s) => s.id == _currentSystem.id);
      final habit = system.habits.firstWhere((h) => h.id == _currentHabit.id);
      setState(() {
        _currentSystem = system;
        _currentHabit = habit;
      });
    } catch (e) {
      // Habit was deleted, navigate back
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  Future<void> _toggleHabit() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    List<DateTime> newCompletedDates = List.from(_currentHabit.completedDates ?? []);
    
    if (_currentHabit.isCompleted) {
      // If habit is currently completed, remove today from completedDates
      newCompletedDates.removeWhere((completedDate) =>
          completedDate.year == today.year &&
          completedDate.month == today.month &&
          completedDate.day == today.day);
    } else {
      // If habit is not completed, add today to completedDates
      newCompletedDates.add(today);
    }
    
    final updatedHabit = _currentHabit.copyWith(
      isCompleted: !_currentHabit.isCompleted,
      completedAt: _currentHabit.isCompleted ? null : now,
      completedDates: newCompletedDates,
    );
    
    await _dataService.updateHabitInSystem(_currentSystem.id, updatedHabit);
    
    // Award XP for completing habit
    if (updatedHabit.isCompleted) {
      await _gamificationService.completeHabit();
    }
    
    _loadHabit();
  }

  Future<void> _deleteHabit() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Habit'),
        content: Text('Are you sure you want to delete "${_currentHabit.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _dataService.deleteHabitFromSystem(_currentSystem.id, _currentHabit.id);
      // Cancel habit reminder notifications
      await NotificationService.cancelHabitReminders(_currentHabit.id);
      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate deletion
      }
    }
  }

  List<DateTime> _getWeekDays(DateTime habitCreatedAt) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    
    // If habit was created this week, show from creation date
    if (habitCreatedAt.isAfter(startOfWeek.subtract(const Duration(days: 1)))) {
      final daysFromCreation = now.difference(habitCreatedAt).inDays;
      final startDate = daysFromCreation >= 6 ? now.subtract(const Duration(days: 6)) : habitCreatedAt;
      return List.generate(7, (index) => startDate.add(Duration(days: index)));
    }
    
    // Otherwise show current week
    return List.generate(7, (index) => startOfWeek.add(Duration(days: index)));
  }

  String _getDayAbbreviation(DateTime date) {
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return days[date.weekday - 1];
  }

  bool _isHabitCompletedOnDate(Habit habit, DateTime date) {
    // Check if this specific date is in the completedDates list
    // Handle null safety for existing habits
    if (habit.completedDates == null || habit.completedDates!.isEmpty) {
      return false;
    }
    
    return habit.completedDates!.any((completedDate) =>
        completedDate.year == date.year &&
        completedDate.month == date.month &&
        completedDate.day == date.day);
  }

  Future<void> _toggleHabitForDate(Habit habit, DateTime date) async {
    // Create a date with only year, month, day (no time)
    final dateOnly = DateTime(date.year, date.month, date.day);
    
    List<DateTime> newCompletedDates = List.from(habit.completedDates ?? []);
    
    // Check if this date is already completed
    final isAlreadyCompleted = newCompletedDates.any((completedDate) =>
        completedDate.year == date.year &&
        completedDate.month == date.month &&
        completedDate.day == date.day);
    
    if (isAlreadyCompleted) {
      // Remove this date from completed dates
      newCompletedDates.removeWhere((completedDate) =>
          completedDate.year == date.year &&
          completedDate.month == date.month &&
          completedDate.day == date.day);
    } else {
      // Add this date to completed dates
      newCompletedDates.add(dateOnly);
    }
    
    // Update the habit with new completed dates
    final updatedHabit = habit.copyWith(
      completedDates: newCompletedDates,
      isCompleted: newCompletedDates.isNotEmpty,
      completedAt: newCompletedDates.isNotEmpty ? DateTime.now() : null,
    );
    
    await _dataService.updateHabitInSystem(_currentSystem.id, updatedHabit);
    
    // Award XP for completing habit (only if it's a new completion)
    if (!isAlreadyCompleted && newCompletedDates.isNotEmpty) {
      await _gamificationService.completeHabit();
    }
    
    _loadHabit();
  }

  Widget _buildWeeklyTracker(Habit habit) {
    final weekDays = _getWeekDays(habit.createdAt);
    
    return Container(
      margin: const EdgeInsets.only(top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: weekDays.map((date) {
          final isCompleted = _isHabitCompletedOnDate(habit, date);
          final isToday = date.year == DateTime.now().year &&
              date.month == DateTime.now().month &&
              date.day == DateTime.now().day;
          
          return GestureDetector(
            key: ValueKey('day_${date.day}_${date.month}'),
            onTap: () {
              _toggleHabitForDate(habit, date);
            },
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isCompleted 
                    ? Colors.green 
                    : Colors.red.withOpacity(0.3),
                borderRadius: BorderRadius.circular(6),
                border: isToday 
                    ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2)
                    : null,
              ),
              child: Center(
                child: Text(
                  _getDayAbbreviation(date),
                  style: TextStyle(
                    color: isCompleted ? Colors.white : Colors.red,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentHabit.name),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Iconsax.edit_2),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddHabitScreen(
                    systemId: _currentSystem.id,
                    habitToEdit: _currentHabit,
                  ),
                ),
              );
              _loadHabit(); // Refresh after returning
            },
          ),
          IconButton(
            icon: const Icon(Iconsax.trash, color: Colors.red),
            onPressed: _deleteHabit,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Habit Info Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _currentHabit.name,
                                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _currentHabit.description,
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: Theme.of(context).textTheme.bodySmall?.color,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'System: ${_currentSystem.name}',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: _toggleHabit,
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: _currentHabit.isCompleted
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: _currentHabit.isCompleted
                                    ? null
                                    : Border.all(
                                        color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                                        width: 2,
                                      ),
                              ),
                              child: _currentHabit.isCompleted
                                  ? const Icon(
                                      Iconsax.tick_circle,
                                      color: Colors.white,
                                      size: 20,
                                    )
                                  : null,
                            ),
                          ),
                        ],
                      ),
                      if (_currentHabit.hasReminder) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Iconsax.notification,
                                color: Theme.of(context).colorScheme.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Reminder: ${_currentHabit.reminderTime?.format(context) ?? "No time set"}',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Weekly Progress
              Text(
                'Weekly Progress',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              _buildWeeklyTracker(_currentHabit),
              
              const SizedBox(height: 24),
              
              // Completion Stats
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Completion Stats',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Created',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).textTheme.bodySmall?.color,
                                  ),
                                ),
                                Text(
                                  '${_currentHabit.createdAt.day}/${_currentHabit.createdAt.month}/${_currentHabit.createdAt.year}',
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_currentHabit.completedAt != null)
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Last Completed',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context).textTheme.bodySmall?.color,
                                    ),
                                  ),
                                  Text(
                                    '${_currentHabit.completedAt!.day}/${_currentHabit.completedAt!.month}/${_currentHabit.completedAt!.year}',
                                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Last Completed',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context).textTheme.bodySmall?.color,
                                    ),
                                  ),
                                  Text(
                                    'Never',
                                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(context).textTheme.bodySmall?.color,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
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
}
