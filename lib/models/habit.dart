import 'package:flutter/material.dart';

enum HabitType {
  oneTime,
  recurring,
}

class Habit {
  final String id;
  final String name;
  final String description;
  final String systemId;
  final HabitType type;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime? completedAt;
  final bool hasReminder;
  final TimeOfDay? reminderTime;
  final List<int> reminderDays; // 0=Sunday, 1=Monday, etc.
  final List<DateTime>? completedDates; // Track individual day completions

  Habit({
    required this.id,
    required this.name,
    required this.description,
    required this.systemId,
    this.type = HabitType.recurring,
    this.isCompleted = false,
    required this.createdAt,
    this.completedAt,
    this.hasReminder = false,
    this.reminderTime,
    this.reminderDays = const [],
    this.completedDates,
  });

  Habit copyWith({
    String? id,
    String? name,
    String? description,
    String? systemId,
    HabitType? type,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? completedAt,
    bool? hasReminder,
    TimeOfDay? reminderTime,
    List<int>? reminderDays,
    List<DateTime>? completedDates,
  }) {
    return Habit(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      systemId: systemId ?? this.systemId,
      type: type ?? this.type,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt,
      hasReminder: hasReminder ?? this.hasReminder,
      reminderTime: reminderTime ?? this.reminderTime,
      reminderDays: reminderDays ?? this.reminderDays,
      completedDates: completedDates ?? this.completedDates,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'systemId': systemId,
      'type': type.name,
      'isCompleted': isCompleted,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'hasReminder': hasReminder,
      'reminderTime': reminderTime != null 
          ? '${reminderTime!.hour}:${reminderTime!.minute.toString().padLeft(2, '0')}'
          : null,
      'reminderDays': reminderDays,
      'completedDates': completedDates?.map((date) => date.toIso8601String()).toList(),
    };
  }

  factory Habit.fromJson(Map<String, dynamic> json) {
    TimeOfDay? parseTime(String? timeString) {
      if (timeString == null) return null;
      final parts = timeString.split(':');
      return TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    }

    return Habit(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      systemId: json['systemId'],
      type: json['type'] != null 
          ? HabitType.values.firstWhere((e) => e.name == json['type'])
          : HabitType.recurring, // Default to recurring for backward compatibility
      isCompleted: json['isCompleted'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      completedAt: json['completedAt'] != null 
          ? DateTime.parse(json['completedAt']) 
          : null,
      hasReminder: json['hasReminder'] ?? false,
      reminderTime: parseTime(json['reminderTime']),
      reminderDays: (json['reminderDays'] as List<dynamic>?)?.cast<int>() ?? [],
      completedDates: json['completedDates'] != null 
          ? (json['completedDates'] as List<dynamic>).map((date) => DateTime.parse(date)).toList()
          : null,
    );
  }
}
