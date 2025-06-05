import 'dart:io';

class ChatMessage {
  final String role;
  final String content;
  final DateTime timestamp;
  final File? image;

  ChatMessage({
    required this.role,
    required this.content,
    required this.timestamp,
    this.image,
  });

  Map<String, dynamic> toJson() {
    return {
      'role': role,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      role: json['role'],
      content: json['content'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}
