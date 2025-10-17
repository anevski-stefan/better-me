import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/system.dart';
import '../models/habit.dart';

class DataService {
  static const String _systemsKey = 'systems';
  static final DataService _instance = DataService._internal();
  factory DataService() => _instance;
  DataService._internal();

  final Uuid _uuid = const Uuid();

  Future<List<System>> getSystems() async {
    final prefs = await SharedPreferences.getInstance();
    final systemsJson = prefs.getStringList(_systemsKey) ?? [];
    
    return systemsJson
        .map((json) => System.fromJson(jsonDecode(json)))
        .toList();
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
}
