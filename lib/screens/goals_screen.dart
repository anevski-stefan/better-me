import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../models/goal.dart';
import '../services/data_service.dart';
import 'add_goal_screen.dart';
import 'goal_detail_screen.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  final DataService _dataService = DataService();
  List<Goal> _goals = [];

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    final goals = await _dataService.getGoals();
    setState(() {
      _goals = goals;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Goals',
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
          child: _goals.isEmpty
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
                        Iconsax.flag,
                        size: 64,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'No Goals Yet',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Create your first goal to get started',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                itemCount: _goals.length,
                itemBuilder: (context, index) {
                  final goal = _goals[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => GoalDetailScreen(goal: goal),
                            ),
                          );
                          _loadGoals();
                        },
                        child: Container(
                          padding: const EdgeInsets.all(20),
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: goal.isCompleted
                                          ? Colors.green.withOpacity(0.1)
                                          : Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      goal.isCompleted ? Iconsax.tick_circle : Iconsax.flag,
                                      color: goal.isCompleted ? Colors.green : Theme.of(context).colorScheme.primary,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          goal.name,
                                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            decoration: goal.isCompleted 
                                                ? TextDecoration.lineThrough 
                                                : null,
                                            color: goal.isCompleted
                                                ? Theme.of(context).textTheme.bodySmall?.color
                                                : null,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          goal.isCompleted ? 'Completed' : 'In Progress',
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            color: goal.isCompleted 
                                                ? Colors.green 
                                                : Theme.of(context).colorScheme.primary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Iconsax.arrow_right_3,
                                    color: Theme.of(context).textTheme.bodySmall?.color,
                                    size: 20,
                                  ),
                                ],
                              ),
                              if (goal.description.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Text(
                                  goal.description,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context).textTheme.bodySmall?.color,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Icon(
                                    Iconsax.calendar_1,
                                    size: 16,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Created ${_formatDate(goal.createdAt)}',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context).textTheme.bodySmall?.color,
                                    ),
                                  ),
                                  if (goal.targetDate != null) ...[
                                    const SizedBox(width: 16),
                                    Icon(
                                      Iconsax.flag,
                                      size: 16,
                                      color: Theme.of(context).colorScheme.secondary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Target: ${_formatDate(goal.targetDate!)}',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Theme.of(context).textTheme.bodySmall?.color,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddGoalScreen(),
            ),
          );
          _loadGoals();
        },
        icon: const Icon(Iconsax.add),
        label: const Text('New Goal'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
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
