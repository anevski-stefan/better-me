import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:intl/intl.dart';
import '../models/system.dart';
import '../models/habit.dart';
import '../models/user_profile.dart';
import '../services/data_service.dart';
import '../services/gamification_service.dart';
import 'system_detail_screen.dart';
import 'add_system_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DataService _dataService = DataService();
  final GamificationService _gamificationService = GamificationService();
  List<System> _systems = [];
  DateTime _selectedDate = DateTime.now();
  UserProfile? _userProfile;

  @override
  void initState() {
    super.initState();
    _loadSystems();
    _loadUserProfile();
  }

  Future<void> _loadSystems() async {
    final systems = await _dataService.getSystems();
    setState(() {
      _systems = systems;
    });
  }

  Future<void> _loadUserProfile() async {
    final profile = await _gamificationService.getProfile();
    setState(() {
      _userProfile = profile;
    });
  }

  List<DateTime> _getDaysInWeek() {
    final today = DateTime.now();
    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
    return List.generate(7, (index) => startOfWeek.add(Duration(days: index)));
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return 'Today';
    }
    final tomorrow = now.add(const Duration(days: 1));
    if (date.year == tomorrow.year && date.month == tomorrow.month && date.day == tomorrow.day) {
      return 'Tomorrow';
    }
    return DateFormat('E, MMM d').format(date);
  }

  List<Habit> _getHabitsForSelectedDate() {
    final allHabits = <Habit>[];
    for (final system in _systems) {
      allHabits.addAll(system.habits);
    }
    
    // Filter habits based on the selected date
    return allHabits.where((habit) {
      // Check if the selected date is before the system's start date
      final system = _systems.firstWhere((s) => s.habits.contains(habit));
      if (system.startDate != null && _selectedDate.isBefore(system.startDate!)) {
        return false;
      }
      
      // For one-time habits, only show on their creation date, start date, or if completed on this date
      if (habit.type == HabitType.oneTime) {
        // Show if it was completed on this date
        if (habit.wasCompletedOnDate(_selectedDate)) {
          return true;
        }
        
        // Show if this is the habit's creation date or start date
        final habitDate = habit.startDate ?? habit.createdAt;
        final isHabitDate = _selectedDate.year == habitDate.year &&
            _selectedDate.month == habitDate.month &&
            _selectedDate.day == habitDate.day;
        
        return isHabitDate;
      }
      
      // For recurring habits, use the existing logic
      return habit.shouldBeAvailableOnDate(_selectedDate);
    }).toList();
  }

  bool _isHabitCompletedForDate(Habit habit, DateTime date) {
    // For one-time habits, check if they were completed at all (not just on this date)
    if (habit.type == HabitType.oneTime) {
      return habit.isCompleted;
    }
    
    // For recurring habits, use the global isCompleted state
    return habit.isCompleted;
  }

  Widget _buildHabitCard(Habit habit, System system) {
    final isCompletedForDate = _isHabitCompletedForDate(habit, _selectedDate);
    
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
                builder: (context) => SystemDetailScreen(system: system),
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
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isCompletedForDate
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: isCompletedForDate
                        ? null
                        : Border.all(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                            width: 2,
                          ),
                  ),
                  child: isCompletedForDate
                      ? const Icon(
                          Iconsax.tick_circle,
                          color: Colors.white,
                          size: 16,
                        )
                      : null,
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
                          decoration: isCompletedForDate
                              ? TextDecoration.lineThrough
                              : null,
                          color: isCompletedForDate
                              ? Theme.of(context).textTheme.bodySmall?.color
                              : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        system.name,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isCompletedForDate)
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
  }


  @override
  Widget build(BuildContext context) {
    final habitsForSelectedDate = _getHabitsForSelectedDate();
    final completedHabits = habitsForSelectedDate.where((h) => _isHabitCompletedForDate(h, _selectedDate)).length;
    final totalHabits = habitsForSelectedDate.length;
    final progressPercentage = totalHabits > 0 ? completedHabits / totalHabits : 0.0;
    final isToday = _selectedDate.year == DateTime.now().year &&
        _selectedDate.month == DateTime.now().month &&
        _selectedDate.day == DateTime.now().day;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Better Me',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
            actions: [
              IconButton(
                icon: const Icon(Iconsax.setting_2),
                onPressed: () {
                  // TODO: Add settings functionality
                },
              ),
            ],
      ),
      body: SafeArea(
        child: Column(
          children: [

            // Day Picker - Light Strip Style
            Container(
              height: 75,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor, // Light background
                borderRadius: BorderRadius.circular(12),
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
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                itemCount: _getDaysInWeek().length,
                itemBuilder: (context, index) {
                  final date = _getDaysInWeek()[index];
                  final isSelected = date.year == _selectedDate.year &&
                      date.month == _selectedDate.month &&
                      date.day == _selectedDate.day;
                  final isTodayDate = date.year == DateTime.now().year &&
                      date.month == DateTime.now().month &&
                      date.day == DateTime.now().day;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedDate = date;
                      });
                    },
                    child: Container(
                      width: 45,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary // Primary color for selected
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            DateFormat('E').format(date),
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : Theme.of(context).textTheme.bodySmall?.color,
                              fontSize: 9,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            date.day.toString(),
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : Theme.of(context).textTheme.titleLarge?.color,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Progress Overview for Selected Day
            if (habitsForSelectedDate.isNotEmpty)
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isToday ? 'Today\'s Progress' : 'Progress for ${_formatDate(_selectedDate)}',
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
                    CircularPercentIndicator(
                      radius: 40,
                      lineWidth: 6,
                      percent: progressPercentage,
                      center: Text(
                        '${(progressPercentage * 100).toInt()}%',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      progressColor: Theme.of(context).colorScheme.primary,
                      backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      circularStrokeCap: CircularStrokeCap.round,
                    ),
                  ],
                ),
              ),

            // Habits List for Selected Day
            Expanded(
              child: habitsForSelectedDate.isEmpty
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
                            isToday ? 'No habits for today' : 'No habits for ${_formatDate(_selectedDate)}',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            isToday
                                ? 'Create your first system to start tracking habits'
                                : 'Select a different day or create new habits',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Theme.of(context).textTheme.bodySmall?.color,
                            ),
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          // Pending habits first
                          ...habitsForSelectedDate.where((h) => !_isHabitCompletedForDate(h, _selectedDate)).map((habit) {
                            final system = _systems.firstWhere((s) => s.habits.contains(habit));
                            return _buildHabitCard(habit, system);
                          }),
                          
                          // Completed habits section
                          if (habitsForSelectedDate.any((h) => _isHabitCompletedForDate(h, _selectedDate))) ...[
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Icon(
                                  Iconsax.tick_circle,
                                  size: 20,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Done',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ...habitsForSelectedDate.where((h) => _isHabitCompletedForDate(h, _selectedDate)).map((habit) {
                              final system = _systems.firstWhere((s) => s.habits.contains(habit));
                              return _buildHabitCard(habit, system);
                            }),
                          ],
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
