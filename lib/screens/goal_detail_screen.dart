import 'package:flutter/material.dart';
import '../models/goal.dart';
import '../models/system.dart';
import '../services/data_service.dart';
import '../services/gamification_service.dart';
import 'system_detail_screen.dart';

class GoalDetailScreen extends StatefulWidget {
  final Goal goal;

  const GoalDetailScreen({super.key, required this.goal});

  @override
  State<GoalDetailScreen> createState() => _GoalDetailScreenState();
}

class _GoalDetailScreenState extends State<GoalDetailScreen> {
  final DataService _dataService = DataService();
  final GamificationService _gamificationService = GamificationService();
  
  late Goal _currentGoal;
  List<System> _systems = [];

  @override
  void initState() {
    super.initState();
    _currentGoal = widget.goal;
    _loadSystems();
  }

  Future<void> _loadSystems() async {
    final systems = await _dataService.getSystems();
    setState(() {
      _systems = systems.where((s) => s.goalId == _currentGoal.id).toList();
    });
  }

  Future<void> _toggleGoal() async {
    final updatedGoal = _currentGoal.copyWith(
      isCompleted: !_currentGoal.isCompleted,
      completedAt: _currentGoal.isCompleted ? null : DateTime.now(),
    );

    await _dataService.updateGoal(updatedGoal);
    
    // Award XP for completing goal
    if (updatedGoal.isCompleted) {
      await _gamificationService.completeGoal();
    }
    
    setState(() {
      _currentGoal = updatedGoal;
    });
  }

  Future<void> _deleteGoal() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Goal'),
        content: const Text('Are you sure you want to delete this goal? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _dataService.deleteGoal(_currentGoal.id);
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentGoal.name),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _deleteGoal,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Goal Info Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _currentGoal.name,
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                decoration: _currentGoal.isCompleted 
                                    ? TextDecoration.lineThrough 
                                    : null,
                              ),
                            ),
                          ),
                          Switch(
                            value: _currentGoal.isCompleted,
                            onChanged: (_) => _toggleGoal(),
                          ),
                        ],
                      ),
                      if (_currentGoal.description.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          _currentGoal.description,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Created ${_formatDate(_currentGoal.createdAt)}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                          if (_currentGoal.targetDate != null) ...[
                            const SizedBox(width: 16),
                            Icon(
                              Icons.flag,
                              size: 16,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Target: ${_formatDate(_currentGoal.targetDate!)}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (_currentGoal.completedAt != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: 16,
                              color: Colors.green,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Completed ${_formatDate(_currentGoal.completedAt!)}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.green,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Connected Systems
              Text(
                'Connected Systems',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              if (_systems.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).dividerColor.withOpacity(0.3),
                    ),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.system_update,
                          size: 48,
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No Systems Connected',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Create systems to work towards this goal',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: _systems.length,
                    itemBuilder: (context, index) {
                      final system = _systems[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Card(
                          child: InkWell(
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SystemDetailScreen(system: system),
                                ),
                              );
                              _loadSystems();
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          system.name,
                                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      Icon(
                                        Icons.arrow_forward_ios,
                                        size: 16,
                                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                                      ),
                                    ],
                                  ),
                                  if (system.description.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      system.description,
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          system.category,
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: Theme.of(context).colorScheme.primary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${system.habits.length} habits',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                        ),
                                      ),
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
            ],
          ),
        ),
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
