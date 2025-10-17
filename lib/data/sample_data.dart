import '../models/system.dart';
import '../models/habit.dart';
import '../services/data_service.dart';

class SampleData {
  static final DataService _dataService = DataService();

  static Future<List<System>> getSampleSystems() async {
    final now = DateTime.now();
    final morningRoutineId = _dataService.generateId();
    final healthFitnessId = _dataService.generateId();
    final learningGrowthId = _dataService.generateId();
    final eveningWindDownId = _dataService.generateId();
    final workProductivityId = _dataService.generateId();
    
    return [
      System(
        id: morningRoutineId,
        name: 'Morning Routine',
        description: 'Start your day with energy and purpose',
        category: 'Health & Fitness',
        createdAt: now.subtract(const Duration(days: 7)),
        habits: [
          Habit(
            id: _dataService.generateId(),
            name: 'Wake up at 6:00 AM',
            description: 'Consistent wake-up time for better sleep cycle',
            systemId: morningRoutineId,
            isCompleted: true,
            createdAt: now.subtract(const Duration(days: 7)),
            completedAt: DateTime.now().subtract(const Duration(hours: 2)),
          ),
          Habit(
            id: _dataService.generateId(),
            name: 'Drink a glass of water',
            description: 'Hydrate your body after 8 hours of sleep',
            systemId: morningRoutineId,
            isCompleted: true,
            createdAt: now.subtract(const Duration(days: 7)),
            completedAt: DateTime.now().subtract(const Duration(hours: 1, minutes: 30)),
          ),
          Habit(
            id: _dataService.generateId(),
            name: '5-minute meditation',
            description: 'Center yourself and set intentions for the day',
            systemId: morningRoutineId,
            isCompleted: false,
            createdAt: now.subtract(const Duration(days: 7)),
          ),
        ],
      ),
      System(
        id: healthFitnessId,
        name: 'Health & Fitness',
        description: 'Maintain physical and mental well-being',
        category: 'Health & Fitness',
        createdAt: now.subtract(const Duration(days: 5)),
        habits: [
          Habit(
            id: _dataService.generateId(),
            name: '30-minute workout',
            description: 'Cardio, strength training, or yoga',
            systemId: healthFitnessId,
            isCompleted: false,
            createdAt: now.subtract(const Duration(days: 5)),
          ),
          Habit(
            id: _dataService.generateId(),
            name: 'Take vitamins',
            description: 'Daily multivitamin and supplements',
            systemId: healthFitnessId,
            isCompleted: true,
            createdAt: now.subtract(const Duration(days: 5)),
            completedAt: DateTime.now().subtract(const Duration(minutes: 30)),
          ),
        ],
      ),
    ];
  }

  static Future<void> initializeSampleData() async {
    final sampleSystems = await getSampleSystems();
    final dataService = DataService();
    
    for (final system in sampleSystems) {
      await dataService.saveSystem(system);
    }
  }

  static Future<void> clearAllData() async {
    final dataService = DataService();
    final systems = await dataService.getSystems();
    
    for (final system in systems) {
      await dataService.deleteSystem(system.id);
    }
  }

  static Future<void> resetToSampleData() async {
    await clearAllData();
    await initializeSampleData();
  }
}