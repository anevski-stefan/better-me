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
  final List<DateTime>? missedDates; // Track individual missed days
  final DateTime? startDate; // Optional start date for the habit
  final bool? useFlexibleFrequency; // Whether to use flexible frequency
  final int? targetDaysPerWeek; // Target number of days per week for flexible frequency

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
    this.missedDates,
    this.startDate,
    this.useFlexibleFrequency,
    this.targetDaysPerWeek,
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
    List<DateTime>? missedDates,
    DateTime? startDate,
    bool? useFlexibleFrequency,
    int? targetDaysPerWeek,
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
      missedDates: missedDates ?? this.missedDates,
      startDate: startDate ?? this.startDate,
      useFlexibleFrequency: useFlexibleFrequency ?? this.useFlexibleFrequency,
      targetDaysPerWeek: targetDaysPerWeek ?? this.targetDaysPerWeek,
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
      'missedDates': missedDates?.map((date) => date.toIso8601String()).toList(),
      'startDate': startDate?.toIso8601String(),
      'useFlexibleFrequency': useFlexibleFrequency,
      'targetDaysPerWeek': targetDaysPerWeek,
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
      missedDates: json['missedDates'] != null 
          ? (json['missedDates'] as List<dynamic>).map((date) => DateTime.parse(date)).toList()
          : null,
      startDate: json['startDate'] != null ? DateTime.parse(json['startDate']) : null,
      useFlexibleFrequency: json['useFlexibleFrequency'],
      targetDaysPerWeek: json['targetDaysPerWeek'],
    );
  }

  /// Check if this habit should be available for completion on a specific date
  bool shouldBeAvailableOnDate(DateTime date) {
    // Check if the date is before the habit's start date
    if (startDate != null && date.isBefore(startDate!)) {
      return false;
    }
    
    // One-time habits are always available until completed
    if (type == HabitType.oneTime) {
      return !isCompleted;
    }
    
    // For flexible frequency habits, available on any day
    if (useFlexibleFrequency == true) {
      return true;
    }
    
    // For recurring habits with specific days, check if the day of week is in reminderDays
    final dayOfWeek = date.weekday % 7; // Convert to 0=Sunday, 1=Monday, etc.
    return reminderDays.contains(dayOfWeek);
  }

  /// Check if this habit was completed on a specific date
  bool wasCompletedOnDate(DateTime date) {
    // If the date is before the habit's start date, it can't be completed
    if (startDate != null && date.isBefore(startDate!)) {
      return false;
    }
    
    if (completedDates == null || completedDates!.isEmpty) {
      return false;
    }
    
    return completedDates!.any((completedDate) =>
        completedDate.year == date.year &&
        completedDate.month == date.month &&
        completedDate.day == date.day);
  }

  /// Check if the weekly target has been met for flexible frequency habits
  bool isWeeklyTargetMet(DateTime weekStart) {
    if (useFlexibleFrequency != true || targetDaysPerWeek == null) {
      return true; // Not a flexible frequency habit, so target is always "met"
    }
    
    if (completedDates == null || completedDates!.isEmpty) {
      return false;
    }
    
    // Calculate the end of the week (6 days after start)
    final weekEnd = weekStart.add(const Duration(days: 6));
    
    // Count completed days in this week
    final completedDaysInWeek = completedDates!.where((completedDate) {
      return completedDate.isAfter(weekStart.subtract(const Duration(days: 1))) &&
             completedDate.isBefore(weekEnd.add(const Duration(days: 1)));
    }).length;
    
    return completedDaysInWeek >= targetDaysPerWeek!;
  }

  /// Get the current week's progress for flexible frequency habits
  Map<String, int> getWeeklyProgress(DateTime weekStart) {
    if (useFlexibleFrequency != true || targetDaysPerWeek == null) {
      return {'completed': 0, 'target': 0, 'remaining': 0};
    }
    
    if (completedDates == null || completedDates!.isEmpty) {
      return {'completed': 0, 'target': targetDaysPerWeek!, 'remaining': targetDaysPerWeek!};
    }
    
    // Calculate the end of the week (6 days after start)
    final weekEnd = weekStart.add(const Duration(days: 6));
    
    // Count completed days in this week
    final completedDaysInWeek = completedDates!.where((completedDate) {
      return completedDate.isAfter(weekStart.subtract(const Duration(days: 1))) &&
             completedDate.isBefore(weekEnd.add(const Duration(days: 1)));
    }).length;
    
    final remaining = (targetDaysPerWeek! - completedDaysInWeek).clamp(0, targetDaysPerWeek!);
    
    return {
      'completed': completedDaysInWeek,
      'target': targetDaysPerWeek!,
      'remaining': remaining,
    };
  }
}
