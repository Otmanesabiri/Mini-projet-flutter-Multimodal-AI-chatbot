import 'dart:io';

class ChatMessage {
  final String role;
  final String content;
  final DateTime timestamp;
  final String? imagePath; // Stocker le chemin de l'image au lieu du File

  // Propriété transient pour l'image (non persistée)
  File? get image => imagePath != null ? File(imagePath!) : null;

  ChatMessage({
    required this.role,
    required this.content,
    required this.timestamp,
    this.imagePath,
  });

  // Constructor pour créer un message avec une image File
  ChatMessage.withImage({
    required this.role,
    required this.content,
    required this.timestamp,
    File? image,
  }) : imagePath = image?.path;

  Map<String, dynamic> toJson() {
    return {
      'role': role,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'imagePath': imagePath,
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      role: json['role'],
      content: json['content'],
      timestamp: DateTime.parse(json['timestamp']),
      imagePath: json['imagePath'],
    );
  }
}
