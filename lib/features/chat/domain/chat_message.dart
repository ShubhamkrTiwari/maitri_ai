class ChatMessage {
  final String id;
  final String sessionId;
  final String sender; // 'user' or 'assistant'
  final String content;
  final DateTime createdAt;
  final bool isCrisisAlert;

  ChatMessage({
    required this.id,
    required this.sessionId,
    required this.sender,
    required this.content,
    required this.createdAt,
    this.isCrisisAlert = false,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String? ?? '',
      sessionId: json['session_id'] as String? ?? '',
      sender: json['sender'] as String? ?? 'user',
      content: json['content'] as String? ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      isCrisisAlert: json['is_crisis_alert'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'session_id': sessionId,
      'sender': sender,
      'content': content,
      'created_at': createdAt.toIso8601String(),
      'is_crisis_alert': isCrisisAlert,
    };
  }

  ChatMessage copyWith({
    String? id,
    String? sessionId,
    String? sender,
    String? content,
    DateTime? createdAt,
    bool? isCrisisAlert,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      sender: sender ?? this.sender,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      isCrisisAlert: isCrisisAlert ?? this.isCrisisAlert,
    );
  }
}
