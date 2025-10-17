import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../models/system.dart';
import '../models/habit.dart';
import '../services/data_service.dart';
import '../services/gamification_service.dart';
import 'add_habit_screen.dart';

class SystemDetailScreen extends StatefulWidget {
  final System system;

  const SystemDetailScreen({super.key, required this.system});

  @override
  State<SystemDetailScreen> createState() => _SystemDetailScreenState();
}

class _SystemDetailScreenState extends State<SystemDetailScreen> {
  final DataService _dataService = DataService();
  final GamificationService _gamificationService = GamificationService();
  late System _currentSystem;

  @override
  void initState() {
    super.initState();
    _currentSystem = widget.system;
  }

  Future<void> _loadSystem() async {
    final systems = await _dataService.getSystems();
    try {
      final system = systems.firstWhere((s) => s.id == _currentSystem.id);
      setState(() {
        _currentSystem = system;
      });
    } catch (e) {
      // System was deleted, navigate back
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  Future<void> _toggleHabit(Habit habit) async {
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
      completedAt: !habit.isCompleted ? now : null,
      completedDates: newCompletedDates,
    );
    
    await _dataService.updateHabitInSystem(_currentSystem.id, updatedHabit);
    
    // Award XP for completing habit
    if (updatedHabit.isCompleted) {
      await _gamificationService.completeHabit();
    }
    
    _loadSystem();
  }

  Future<void> _toggleHabitForDate(Habit habit, DateTime date) async {
    print('Toggling habit ${habit.name} for date ${date.day}/${date.month}');
    
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
      completedAt: newCompletedDates.isNotEmpty ? newCompletedDates.last : null,
    );
    
    await _dataService.updateHabitInSystem(_currentSystem.id, updatedHabit);
    
    // Award XP for completing habit (only if it's a new completion)
    if (!isAlreadyCompleted && newCompletedDates.isNotEmpty) {
      await _gamificationService.completeHabit();
    }
    
    _loadSystem();
  }

  Future<void> _deleteHabit(Habit habit) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Habit'),
        content: Text('Are you sure you want to delete "${habit.name}"?'),
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
      await _dataService.deleteHabitFromSystem(_currentSystem.id, habit.id);
      _loadSystem();
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
              print('Day ${_getDayAbbreviation(date)} clicked for habit ${habit.name}');
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
        title: Text(_currentSystem.name),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete System'),
                  content: Text('Are you sure you want to delete "${_currentSystem.name}"?'),
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
                await _dataService.deleteSystem(_currentSystem.id);
                if (mounted) {
                  Navigator.pop(context, true); // Pass true to indicate deletion
                }
              }
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _currentSystem.description,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  '${_currentSystem.habits.length} habits',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: _currentSystem.habits.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.checklist,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No habits yet',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Add your first habit to get started',
                          style: TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _currentSystem.habits.length,
                    itemBuilder: (context, index) {
                      final habit = _currentSystem.habits[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
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
                                          habit.name,
                                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            decoration: habit.isCompleted 
                                                ? TextDecoration.lineThrough 
                                                : null,
                                            color: habit.isCompleted 
                                                ? Colors.grey 
                                                : null,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          habit.description,
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: Theme.of(context).textTheme.bodySmall?.color,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Checkbox(
                                        value: habit.isCompleted,
                                        onChanged: (value) => _toggleHabit(habit),
                                      ),
                                      IconButton(
                                        icon: const Icon(Iconsax.trash, color: Colors.red, size: 20),
                                        onPressed: () => _deleteHabit(habit),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              _buildWeeklyTracker(habit),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddHabitScreen(systemId: _currentSystem.id),
            ),
          );
          _loadSystem(); // Refresh after returning
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
