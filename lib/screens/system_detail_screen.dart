import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../models/system.dart';
import '../models/habit.dart';
import '../services/data_service.dart';
import '../services/gamification_service.dart';
import '../services/notification_service.dart';
import 'add_habit_screen.dart';
import 'add_system_screen.dart';
import 'habit_detail_screen.dart';

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
    List<DateTime> newMissedDates = List.from(habit.missedDates ?? []);
    
    // Check current state
    final isCompleted = newCompletedDates.any((completedDate) =>
        completedDate.year == date.year &&
        completedDate.month == date.month &&
        completedDate.day == date.day);
    
    final isMissed = newMissedDates.any((missedDate) =>
        missedDate.year == date.year &&
        missedDate.month == date.month &&
        missedDate.day == date.day);
    
    // Toggle through states: default → completed → missed → default
    if (isCompleted) {
      // Remove from completed, set to missed
      newCompletedDates.removeWhere((completedDate) =>
          completedDate.year == date.year &&
          completedDate.month == date.month &&
          completedDate.day == date.day);
      if (!newMissedDates.any((missedDate) =>
          missedDate.year == date.year &&
          missedDate.month == date.month &&
          missedDate.day == date.day)) {
        newMissedDates.add(dateOnly);
      }
    } else if (isMissed) {
      // Remove from missed, set to default
      newMissedDates.removeWhere((missedDate) =>
          missedDate.year == date.year &&
          missedDate.month == date.month &&
          missedDate.day == date.day);
    } else {
      // Set to completed
      if (!newCompletedDates.any((completedDate) =>
          completedDate.year == date.year &&
          completedDate.month == date.month &&
          completedDate.day == date.day)) {
        newCompletedDates.add(dateOnly);
      }
    }
    
    // Update the habit with new states
    final updatedHabit = habit.copyWith(
      completedDates: newCompletedDates,
      missedDates: newMissedDates,
      isCompleted: newCompletedDates.isNotEmpty,
      completedAt: newCompletedDates.isNotEmpty ? newCompletedDates.last : null,
    );
    
    await _dataService.updateHabitInSystem(_currentSystem.id, updatedHabit);
    
    // Award XP for completing habit (only if it's a new completion)
    if (!isCompleted && newCompletedDates.isNotEmpty) {
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
      // Cancel habit reminder notifications
      await NotificationService.cancelHabitReminders(habit.id);
      _loadSystem();
    }
  }

  List<DateTime> _getWeekDays() {
    final now = DateTime.now();
    final systemStartDate = _currentSystem.startDate ?? _currentSystem.createdAt;
    
    // If system start date is in the future, show the week starting from the start date
    if (systemStartDate.isAfter(now)) {
      return List.generate(7, (index) => systemStartDate.add(Duration(days: index)));
    }
    
    // If system start date is in the past, show current week (Monday to Sunday)
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    return List.generate(7, (index) => startOfWeek.add(Duration(days: index)));
  }

  List<DateTime> _getWeekDaysForHabit(Habit habit) {
    final now = DateTime.now();
    final systemStartDate = _currentSystem.startDate ?? _currentSystem.createdAt;
    final habitStartDate = habit.startDate;
    
    // Determine which start date to use
    DateTime effectiveStartDate;
    if (habitStartDate != null && habitStartDate.isAfter(now)) {
      // Use habit start date if it's in the future
      effectiveStartDate = habitStartDate;
    } else if (systemStartDate.isAfter(now)) {
      // Use system start date if it's in the future
      effectiveStartDate = systemStartDate;
    } else {
      // Use current week if both are in the past
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      return List.generate(7, (index) => startOfWeek.add(Duration(days: index)));
    }
    
    // If we have a future start date, show the week starting from that date
    return List.generate(7, (index) => effectiveStartDate.add(Duration(days: index)));
  }

  String _getDayAbbreviation(DateTime date) {
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return days[date.weekday - 1];
  }

  void _showFutureDayMessage(DateTime date) {
    final now = DateTime.now();
    final daysUntil = date.difference(now).inDays;
    
    String message;
    if (daysUntil == 1) {
      message = "This day is tomorrow! You can't track habits for future days.";
    } else if (daysUntil > 1) {
      message = "This day is in ${daysUntil} days! You can't track habits for future days.";
    } else {
      message = "This day is in the future! You can't track habits for future days.";
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Iconsax.info_circle,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
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

  bool _isHabitMissedOnDate(Habit habit, DateTime date) {
    // Check if this specific date is in the missedDates list
    // Handle null safety for existing habits
    if (habit.missedDates == null || habit.missedDates!.isEmpty) {
      return false;
    }
    
    return habit.missedDates!.any((missedDate) =>
        missedDate.year == date.year &&
        missedDate.month == date.month &&
        missedDate.day == date.day);
  }

  Widget _buildWeeklyTracker(Habit habit) {
    // For one-time habits, show only one day (today, system start date, or habit start date)
    if (habit.type == HabitType.oneTime) {
      final now = DateTime.now();
      final systemStartDate = _currentSystem.startDate ?? _currentSystem.createdAt;
      final habitStartDate = habit.startDate;
      
      // Use habit start date if available and in the future, otherwise use system start date
      DateTime targetDate;
      if (habitStartDate != null && habitStartDate.isAfter(now)) {
        targetDate = habitStartDate;
      } else if (systemStartDate.isAfter(now)) {
        targetDate = systemStartDate;
      } else {
        targetDate = now;
      }
      
      return Container(
        margin: const EdgeInsets.only(top: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            _buildDayTracker(habit, targetDate),
          ],
        ),
      );
    }
    
    // For recurring habits, show the full week based on habit start date or system start date
    final weekDays = _getWeekDaysForHabit(habit);
    
    return Container(
      margin: const EdgeInsets.only(top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: weekDays.map((date) => _buildDayTracker(habit, date)).toList()
          .expand((widget) => [widget, const SizedBox(width: 8)]).toList()
          ..removeLast(), // Remove the last SizedBox
      ),
    );
  }

  Widget _buildDayTracker(Habit habit, DateTime date) {
    final isCompleted = _isHabitCompletedOnDate(habit, date);
    final isMissed = _isHabitMissedOnDate(habit, date);
    final now = DateTime.now();
    final isToday = date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
    final isFuture = date.isAfter(now);
    
    // Disable future days - only allow clicking on today and past days
    final canClick = !isFuture;
    
    return GestureDetector(
      key: ValueKey('day_${habit.id}_${date.millisecondsSinceEpoch}'),
      onTap: canClick ? () {
        print('Day ${_getDayAbbreviation(date)} clicked for habit ${habit.name}');
        _toggleHabitForDate(habit, date);
      } : () {
        // Show message for disabled future days
        _showFutureDayMessage(date);
      },
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: isFuture
              ? Colors.grey.withOpacity(0.1) // Future days - very light gray
              : isCompleted 
                  ? Colors.green 
                  : isMissed
                      ? Colors.red.withOpacity(0.3) // Missed days - red
                      : Colors.grey.withOpacity(0.3), // Default gray
          borderRadius: BorderRadius.circular(6),
          border: isToday 
              ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2)
              : null,
        ),
        child: Center(
          child: Text(
            _getDayAbbreviation(date),
            style: TextStyle(
              color: isFuture
                  ? Colors.grey.withOpacity(0.4) // Future days - very light gray text
                  : isCompleted 
                      ? Colors.white 
                      : isMissed
                          ? Colors.red.shade700 // Missed days - red text
                          : Colors.grey.shade700, // Default gray text
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
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
            icon: const Icon(Iconsax.edit_2),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddSystemScreen(systemToEdit: _currentSystem),
                ),
              );
              _loadSystem(); // Refresh after returning
            },
          ),
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
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Created ${_formatDate(_currentSystem.createdAt)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    if (_currentSystem.startDate != null && 
                        _currentSystem.startDate!.difference(_currentSystem.createdAt).inDays != 0) ...[
                      const SizedBox(width: 16),
                      Icon(
                        Icons.play_arrow,
                        size: 16,
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Start: ${_formatDate(_currentSystem.startDate!)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                    if (_currentSystem.targetDate != null) ...[
                      const SizedBox(width: 16),
                      Icon(
                        Icons.flag,
                        size: 16,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Target: ${_formatDate(_currentSystem.targetDate!)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ],
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
                      return GestureDetector(
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => HabitDetailScreen(
                                habit: habit,
                                system: _currentSystem,
                              ),
                            ),
                          );
                          _loadSystem(); // Refresh after returning
                        },
                        child: Card(
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
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
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
                                                  ),
                                                ],
                                              ),
                                              if (habit.type == HabitType.oneTime) ...[
                                                const SizedBox(height: 4),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                  decoration: BoxDecoration(
                                                    color: Colors.orange.withOpacity(0.15),
                                                    borderRadius: BorderRadius.circular(12),
                                                    border: Border.all(
                                                      color: Colors.orange.withOpacity(0.3),
                                                      width: 0.5,
                                                    ),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        Iconsax.flag_2,
                                                        size: 12,
                                                        color: Colors.orange.shade700,
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        'One-time',
                                                        style: TextStyle(
                                                          color: Colors.orange.shade700,
                                                          fontSize: 11,
                                                          fontWeight: FontWeight.w600,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ],
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
                                        IconButton(
                                          icon: const Icon(Iconsax.edit_2, size: 20),
                                          onPressed: () async {
                                            await Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => AddHabitScreen(
                                                  systemId: _currentSystem.id,
                                                  habitToEdit: habit,
                                                ),
                                              ),
                                            );
                                            _loadSystem(); // Refresh after returning
                                          },
                                        ),
                                        IconButton(
                                          icon: const Icon(Iconsax.trash, size: 20),
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
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: "system_detail_fab",
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now).inDays;
    
    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Tomorrow';
    } else if (difference == -1) {
      return 'Yesterday';
    } else if (difference > 0) {
      return 'In $difference days';
    } else {
      return '${-difference} days ago';
    }
  }
}

