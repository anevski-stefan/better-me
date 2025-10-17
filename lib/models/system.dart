import 'habit.dart';

class System {
  final String id;
  final String name;
  final String description;
  final DateTime createdAt;
  final List<Habit> habits;

  System({
    required this.id,
    required this.name,
    required this.description,
    required this.createdAt,
    this.habits = const [],
  });

  System copyWith({
    String? id,
    String? name,
    String? description,
    DateTime? createdAt,
    List<Habit>? habits,
  }) {
    return System(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      habits: habits ?? this.habits,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'habits': habits.map((habit) => habit.toJson()).toList(),
    };
  }

  factory System.fromJson(Map<String, dynamic> json) {
    return System(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      createdAt: DateTime.parse(json['createdAt']),
      habits: (json['habits'] as List<dynamic>?)
          ?.map((habitJson) => Habit.fromJson(habitJson))
          .toList() ?? [],
    );
  }
}
