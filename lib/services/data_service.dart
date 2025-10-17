import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/system.dart';
import '../models/habit.dart';
import '../models/goal.dart';
import '../data/sample_data.dart';

class DataService {
  static const String _systemsKey = 'systems';
  static const String _goalsKey = 'goals';
  static const String _sampleDataInitializedKey = 'sample_data_initialized';
  static final DataService _instance = DataService._internal();
  factory DataService() => _instance;
  DataService._internal();

  final Uuid _uuid = const Uuid();

  Future<List<System>> getSystems() async {
    final prefs = await SharedPreferences.getInstance();
    final systemsJson = prefs.getStringList(_systemsKey) ?? [];
    final sampleDataInitialized = prefs.getBool(_sampleDataInitializedKey) ?? false;
    
    if (systemsJson.isEmpty && !sampleDataInitialized) {
      // Initialize with sample data only if no data exists and sample data hasn't been initialized yet
      await _initializeSampleData();
      await prefs.setBool(_sampleDataInitializedKey, true);
      // Get the data again after initialization
      final newSystemsJson = prefs.getStringList(_systemsKey) ?? [];
      return newSystemsJson
          .map((json) => System.fromJson(jsonDecode(json)))
          .toList();
    }
    
    return systemsJson
        .map((json) => System.fromJson(jsonDecode(json)))
        .toList();
  }

  Future<void> _initializeSampleData() async {
    final sampleSystems = await SampleData.getSampleSystems();
    await _saveAllSystems(sampleSystems);
  }

  Future<void> saveSystem(System system) async {
    final prefs = await SharedPreferences.getInstance();
    final systems = await getSystems();
    
    final existingIndex = systems.indexWhere((s) => s.id == system.id);
    if (existingIndex >= 0) {
      systems[existingIndex] = system;
    } else {
      systems.add(system);
    }
    
    final systemsJson = systems
        .map((s) => jsonEncode(s.toJson()))
        .toList();
    
    await prefs.setStringList(_systemsKey, systemsJson);
  }

  Future<void> deleteSystem(String systemId) async {
    final prefs = await SharedPreferences.getInstance();
    final systems = await getSystems();
    
    systems.removeWhere((s) => s.id == systemId);
    
    final systemsJson = systems
        .map((s) => jsonEncode(s.toJson()))
        .toList();
    
    await prefs.setStringList(_systemsKey, systemsJson);
  }

  Future<void> addHabitToSystem(String systemId, Habit habit) async {
    final systems = await getSystems();
    final systemIndex = systems.indexWhere((s) => s.id == systemId);
    
    if (systemIndex >= 0) {
      final system = systems[systemIndex];
      final updatedHabits = List<Habit>.from(system.habits)..add(habit);
      final updatedSystem = system.copyWith(habits: updatedHabits);
      systems[systemIndex] = updatedSystem;
      
      await _saveAllSystems(systems);
    }
  }

  Future<void> updateHabitInSystem(String systemId, Habit habit) async {
    final systems = await getSystems();
    final systemIndex = systems.indexWhere((s) => s.id == systemId);
    
    if (systemIndex >= 0) {
      final system = systems[systemIndex];
      final updatedHabits = system.habits.map((h) => h.id == habit.id ? habit : h).toList();
      final updatedSystem = system.copyWith(habits: updatedHabits);
      systems[systemIndex] = updatedSystem;
      
      await _saveAllSystems(systems);
    }
  }

  Future<void> deleteHabitFromSystem(String systemId, String habitId) async {
    final systems = await getSystems();
    final systemIndex = systems.indexWhere((s) => s.id == systemId);
    
    if (systemIndex >= 0) {
      final system = systems[systemIndex];
      final updatedHabits = system.habits.where((h) => h.id != habitId).toList();
      final updatedSystem = system.copyWith(habits: updatedHabits);
      systems[systemIndex] = updatedSystem;
      
      await _saveAllSystems(systems);
    }
  }

  Future<void> _saveAllSystems(List<System> systems) async {
    final prefs = await SharedPreferences.getInstance();
    final systemsJson = systems
        .map((s) => jsonEncode(s.toJson()))
        .toList();
    
    await prefs.setStringList(_systemsKey, systemsJson);
  }

  String generateId() {
    return _uuid.v4();
  }

  // Method to force reset to sample data
  Future<void> resetToSampleData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_systemsKey);
    await prefs.setBool(_sampleDataInitializedKey, false);
    await _initializeSampleData();
    await prefs.setBool(_sampleDataInitializedKey, true);
  }

  // Goal-related methods
  Future<List<Goal>> getGoals() async {
    final prefs = await SharedPreferences.getInstance();
    final goalsJson = prefs.getStringList(_goalsKey) ?? [];
    
    return goalsJson
        .map((json) => Goal.fromJson(jsonDecode(json)))
        .toList();
  }

  Future<void> addGoal(Goal goal) async {
    final prefs = await SharedPreferences.getInstance();
    final goals = await getGoals();
    
    goals.add(goal);
    
    final goalsJson = goals
        .map((g) => jsonEncode(g.toJson()))
        .toList();
    
    await prefs.setStringList(_goalsKey, goalsJson);
  }

  Future<void> updateGoal(Goal goal) async {
    final prefs = await SharedPreferences.getInstance();
    final goals = await getGoals();
    
    final existingIndex = goals.indexWhere((g) => g.id == goal.id);
    if (existingIndex >= 0) {
      goals[existingIndex] = goal;
    }
    
    final goalsJson = goals
        .map((g) => jsonEncode(g.toJson()))
        .toList();
    
    await prefs.setStringList(_goalsKey, goalsJson);
  }

  Future<void> deleteGoal(String goalId) async {
    final prefs = await SharedPreferences.getInstance();
    final goals = await getGoals();
    
    goals.removeWhere((g) => g.id == goalId);
    
    final goalsJson = goals
        .map((g) => jsonEncode(g.toJson()))
        .toList();
    
    await prefs.setStringList(_goalsKey, goalsJson);
  }
}
