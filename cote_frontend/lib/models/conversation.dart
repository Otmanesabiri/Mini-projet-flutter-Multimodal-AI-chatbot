import 'package:uuid/uuid.dart';
import 'message.dart';

class Conversation {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ChatMessage> messages;

  Conversation({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.messages,
  });

  Conversation.create({
    String? title,
    List<ChatMessage>? messages,
  }) : id = const Uuid().v4(),
       title = title ?? 'Nouvelle conversation',
       createdAt = DateTime.now(),
       updatedAt = DateTime.now(),
       messages = messages ?? [];

  // Méthode pour mettre à jour la conversation
  Conversation copyWith({
    String? title,
    DateTime? updatedAt,
    List<ChatMessage>? messages,
  }) {
    return Conversation(
      id: id,
      title: title ?? this.title,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      messages: messages ?? this.messages,
    );
  }

  // Ajouter un message à la conversation
  void addMessage(ChatMessage message) {
    messages.add(message);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'messages': messages.map((m) => m.toJson()).toList(),
    };
  }

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'],
      title: json['title'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      messages: (json['messages'] as List)
          .map((m) => ChatMessage.fromJson(m))
          .toList(),
    );
  }
}