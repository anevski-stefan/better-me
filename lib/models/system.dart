import 'habit.dart';

class System {
  final String id;
  final String name;
  final String description;
  final String category;
  final String? goalId;
  final DateTime createdAt;
  final DateTime? startDate;
  final DateTime? targetDate;
  final List<Habit> habits;

  System({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    this.goalId,
    required this.createdAt,
    this.startDate,
    this.targetDate,
    this.habits = const [],
  });

  System copyWith({
    String? id,
    String? name,
    String? description,
    String? category,
    String? goalId,
    DateTime? createdAt,
    DateTime? startDate,
    DateTime? targetDate,
    List<Habit>? habits,
  }) {
    return System(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      goalId: goalId ?? this.goalId,
      createdAt: createdAt ?? this.createdAt,
      startDate: startDate,
      targetDate: targetDate,
      habits: habits ?? this.habits,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'goalId': goalId,
      'createdAt': createdAt.toIso8601String(),
      'startDate': startDate?.toIso8601String(),
      'targetDate': targetDate?.toIso8601String(),
      'habits': habits.map((habit) => habit.toJson()).toList(),
    };
  }

  factory System.fromJson(Map<String, dynamic> json) {
    return System(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      category: json['category'] ?? 'General',
      goalId: json['goalId'],
      createdAt: DateTime.parse(json['createdAt']),
      startDate: json['startDate'] != null ? DateTime.parse(json['startDate']) : null,
      targetDate: json['targetDate'] != null ? DateTime.parse(json['targetDate']) : null,
      habits: (json['habits'] as List<dynamic>?)
          ?.map((habitJson) => Habit.fromJson(habitJson))
          .toList() ?? [],
    );
  }
}
