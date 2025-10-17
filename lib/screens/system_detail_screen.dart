import 'package:flutter/material.dart';
import '../models/system.dart';
import '../models/habit.dart';
import '../services/data_service.dart';
import 'add_habit_screen.dart';

class SystemDetailScreen extends StatefulWidget {
  final System system;

  const SystemDetailScreen({super.key, required this.system});

  @override
  State<SystemDetailScreen> createState() => _SystemDetailScreenState();
}

class _SystemDetailScreenState extends State<SystemDetailScreen> {
  final DataService _dataService = DataService();
  late System _currentSystem;

  @override
  void initState() {
    super.initState();
    _currentSystem = widget.system;
  }

  Future<void> _loadSystem() async {
    final systems = await _dataService.getSystems();
    final system = systems.firstWhere((s) => s.id == _currentSystem.id);
    setState(() {
      _currentSystem = system;
    });
  }

  Future<void> _toggleHabit(Habit habit) async {
    final updatedHabit = habit.copyWith(
      isCompleted: !habit.isCompleted,
      completedAt: !habit.isCompleted ? DateTime.now() : null,
    );
    
    await _dataService.updateHabitInSystem(_currentSystem.id, updatedHabit);
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
                  Navigator.pop(context);
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
                        margin: const EdgeInsets.only(bottom: 8),
                        child: CheckboxListTile(
                          title: Text(
                            habit.name,
                            style: TextStyle(
                              decoration: habit.isCompleted 
                                  ? TextDecoration.lineThrough 
                                  : null,
                              color: habit.isCompleted 
                                  ? Colors.grey 
                                  : null,
                            ),
                          ),
                          subtitle: Text(habit.description),
                          value: habit.isCompleted,
                          onChanged: (value) => _toggleHabit(habit),
                          secondary: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteHabit(habit),
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
