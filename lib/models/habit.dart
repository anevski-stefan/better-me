class Habit {
  final String id;
  final String name;
  final String description;
  final String systemId;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime? completedAt;

  Habit({
    required this.id,
    required this.name,
    required this.description,
    required this.systemId,
    this.isCompleted = false,
    required this.createdAt,
    this.completedAt,
  });

  Habit copyWith({
    String? id,
    String? name,
    String? description,
    String? systemId,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? completedAt,
  }) {
    return Habit(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      systemId: systemId ?? this.systemId,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'systemId': systemId,
      'isCompleted': isCompleted,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  factory Habit.fromJson(Map<String, dynamic> json) {
    return Habit(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      systemId: json['systemId'],
      isCompleted: json['isCompleted'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      completedAt: json['completedAt'] != null 
          ? DateTime.parse(json['completedAt']) 
          : null,
    );
  }
}
