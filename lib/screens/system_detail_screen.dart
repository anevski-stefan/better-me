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
    final updatedHabit = habit.copyWith(
      isCompleted: !habit.isCompleted,
      completedAt: !habit.isCompleted ? DateTime.now() : null,
    );
    
    await _dataService.updateHabitInSystem(_currentSystem.id, updatedHabit);
    
    // Award XP for completing habit
    if (updatedHabit.isCompleted) {
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
    // For now, we'll use a simple logic based on habit completion
    // In a real app, you'd store daily completion data
    if (!habit.isCompleted) return false;
    
    // If habit was completed today and the date is today, return true
    if (habit.completedAt != null && 
        habit.completedAt!.year == date.year &&
        habit.completedAt!.month == date.month &&
        habit.completedAt!.day == date.day) {
      return true;
    }
    
    // For demo purposes, show some random completion pattern
    // In a real app, you'd have proper daily tracking
    return date.weekday % 2 == 0; // Even days of week
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
          
          return Container(
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
