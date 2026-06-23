// lib/features/chat_ai/models/chat_message.dart
// Extended message model khusus untuk fitur Chat AI Assessment 3.
// TIDAK mengubah MessageModel yang digunakan fitur lain.

class ChatMessage {
  final String id;
  final String chatId;
  final String content;
  final String role; // 'user' | 'assistant'
  final DateTime timestamp;
  final bool isFavorite;
  final String? replyToId;
  final String? replyToContent;
  final String? replyToRole;

  ChatMessage({
    required this.id,
    required this.chatId,
    required this.content,
    required this.role,
    required this.timestamp,
    this.isFavorite = false,
    this.replyToId,
    this.replyToContent,
    this.replyToRole,
  });

  bool get isUser => role == 'user';
  bool get isAssistant => role == 'assistant';
  bool get hasReply => replyToId != null && replyToContent != null;

  ChatMessage copyWith({
    String? id,
    String? chatId,
    String? content,
    String? role,
    DateTime? timestamp,
    bool? isFavorite,
    String? replyToId,
    String? replyToContent,
    String? replyToRole,
    bool clearReply = false,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      content: content ?? this.content,
      role: role ?? this.role,
      timestamp: timestamp ?? this.timestamp,
      isFavorite: isFavorite ?? this.isFavorite,
      replyToId: clearReply ? null : (replyToId ?? this.replyToId),
      replyToContent: clearReply ? null : (replyToContent ?? this.replyToContent),
      replyToRole: clearReply ? null : (replyToRole ?? this.replyToRole),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'chatId': chatId,
      'content': content,
      'role': role,
      'timestamp': timestamp.toIso8601String(),
      'isFavorite': isFavorite,
      'replyToId': replyToId,
      'replyToContent': replyToContent,
      'replyToRole': replyToRole,
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'] as String? ?? '',
      chatId: map['chatId'] as String? ?? '',
      content: map['content'] as String? ?? '',
      role: map['role'] as String? ?? 'user',
      timestamp: map['timestamp'] != null
          ? DateTime.tryParse(map['timestamp'] as String) ?? DateTime.now()
          : DateTime.now(),
      isFavorite: map['isFavorite'] as bool? ?? false,
      replyToId: map['replyToId'] as String?,
      replyToContent: map['replyToContent'] as String?,
      replyToRole: map['replyToRole'] as String?,
    );
  }
}
