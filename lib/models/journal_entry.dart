class JournalEntry {
  final String id;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String mood; // e.g., 'happy', 'sad', 'neutral', 'excited', 'anxious'
  final List<String> tags;
  final bool isPrivate;

  JournalEntry({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    this.updatedAt,
    this.mood = 'neutral',
    this.tags = const [],
    this.isPrivate = false,
  });

  JournalEntry copyWith({
    String? id,
    String? title,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? mood,
    List<String>? tags,
    bool? isPrivate,
  }) {
    return JournalEntry(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      mood: mood ?? this.mood,
      tags: tags ?? this.tags,
      isPrivate: isPrivate ?? this.isPrivate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'mood': mood,
      'tags': tags,
      'isPrivate': isPrivate,
    };
  }

  factory JournalEntry.fromJson(Map<String, dynamic> json) {
    return JournalEntry(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      mood: json['mood'] ?? 'neutral',
      tags: List<String>.from(json['tags'] ?? []),
      isPrivate: json['isPrivate'] ?? false,
    );
  }
}
