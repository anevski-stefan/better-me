class Goal {
  final String id;
  final String name;
  final String description;
  final DateTime createdAt;
  final DateTime? targetDate;
  final bool isCompleted;
  final DateTime? completedAt;

  Goal({
    required this.id,
    required this.name,
    required this.description,
    required this.createdAt,
    this.targetDate,
    this.isCompleted = false,
    this.completedAt,
  });

  Goal copyWith({
    String? id,
    String? name,
    String? description,
    DateTime? createdAt,
    DateTime? targetDate,
    bool? isCompleted,
    DateTime? completedAt,
  }) {
    return Goal(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      targetDate: targetDate,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'targetDate': targetDate?.toIso8601String(),
      'isCompleted': isCompleted,
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  factory Goal.fromJson(Map<String, dynamic> json) {
    return Goal(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      createdAt: DateTime.parse(json['createdAt']),
      targetDate: json['targetDate'] != null ? DateTime.parse(json['targetDate']) : null,
      isCompleted: json['isCompleted'] ?? false,
      completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt']) : null,
    );
  }
}
