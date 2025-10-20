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
  DateTime _currentDisplayMonth = DateTime.now();

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

  bool _isHabitAvailableOnDate(Habit habit, DateTime date) {
    // Check if the habit should be available on this date based on frequency
    return habit.shouldBeAvailableOnDate(date);
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

  Widget _buildCalendarView(Habit habit) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Month navigation header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () {
                    setState(() {
                      _currentDisplayMonth = DateTime(
                        _currentDisplayMonth.year,
                        _currentDisplayMonth.month - 1,
                      );
                    });
                  },
                ),
                Text(
                  '${_getMonthName(_currentDisplayMonth.month)} ${_currentDisplayMonth.year}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () {
                    setState(() {
                      _currentDisplayMonth = DateTime(
                        _currentDisplayMonth.year,
                        _currentDisplayMonth.month + 1,
                      );
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildMonthView(habit, _currentDisplayMonth),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMonthView(Habit habit, DateTime month) {
    final startOfMonth = DateTime(month.year, month.month, 1);
    final endOfMonth = DateTime(month.year, month.month + 1, 0);
    final firstDayOfWeek = startOfMonth.weekday % 7; // 0 = Sunday
    
    // Generate calendar days
    final List<Widget> calendarDays = [];
    
    // Add empty cells for days before the first day of the month
    for (int i = 0; i < firstDayOfWeek; i++) {
      calendarDays.add(Container());
    }
    
    // Add days of the month
    for (int day = 1; day <= endOfMonth.day; day++) {
      final date = DateTime(month.year, month.month, day);
      final isCompleted = _isHabitCompletedOnDate(habit, date);
      final isMissed = _isHabitMissedOnDate(habit, date);
      final isToday = date.year == DateTime.now().year && 
                     date.month == DateTime.now().month && 
                     date.day == DateTime.now().day;
      
      calendarDays.add(
        Container(
            width: 40,
            height: 40,
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: isCompleted 
                  ? Colors.green 
                  : isMissed
                      ? Colors.red.withOpacity(0.3)
                      : Colors.grey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
              border: isToday 
                  ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2)
                  : null,
            ),
            child: Center(
              child: Text(
                day.toString(),
                style: TextStyle(
                  color: isCompleted 
                      ? Colors.white 
                      : isMissed
                          ? Colors.red.shade700
                          : Colors.grey.shade700,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
        ),
      );
    }
    
    return Column(
      children: [
        // Day headers
        Row(
          children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
              .map((day) => Expanded(
                    child: Center(
                      child: Text(
                        day,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 8),
        // Calendar grid
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 7,
          childAspectRatio: 1.0,
          children: calendarDays,
        ),
      ],
    );
  }
  
  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
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
            icon: const Icon(Iconsax.trash),
            onPressed: _deleteHabit,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
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
              _buildCalendarView(_currentHabit),
              
            ],
          ),
        ),
      ),
    );
  }
}
