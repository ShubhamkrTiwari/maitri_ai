class MemoryModel {
  final String id;
  final String userId;
  final String content;
  final DateTime createdAt;

  MemoryModel({
    required this.id,
    required this.userId,
    required this.content,
    required this.createdAt,
  });

  factory MemoryModel.fromJson(Map<String, dynamic> json) {
    return MemoryModel(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      content: json['content'] as String? ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'content': content,
      'created_at': createdAt.toIso8601String(),
    };
  }

  MemoryModel copyWith({
    String? id,
    String? userId,
    String? content,
    DateTime? createdAt,
  }) {
    return MemoryModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
