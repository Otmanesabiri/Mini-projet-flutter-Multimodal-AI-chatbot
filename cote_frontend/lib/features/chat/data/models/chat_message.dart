import 'package:equatable/equatable.dart';

enum MessageRole { user, assistant, system }
enum MessageContentType { text, image, audio, video, file, code }

class ChatMessage extends Equatable {
  final String id;
  final MessageRole role;
  final DateTime timestamp;
  final List<MessageContent> contents;

  const ChatMessage({
    required this.id,
    required this.role,
    required this.timestamp,
    required this.contents,
  });

  factory ChatMessage.user({
    required String text,
    String? imageUrl,
    String? audioUrl,
    String? fileUrl,
  }) {
    final List<MessageContent> contents = [];
    
    if (text.isNotEmpty) {
      contents.add(MessageContent(type: MessageContentType.text, content: text));
    }
    
    if (imageUrl != null) {
      contents.add(MessageContent(type: MessageContentType.image, content: imageUrl));
    }
    
    if (audioUrl != null) {
      contents.add(MessageContent(type: MessageContentType.audio, content: audioUrl));
    }
    
    if (fileUrl != null) {
      contents.add(MessageContent(type: MessageContentType.file, content: fileUrl));
    }
    
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: MessageRole.user,
      timestamp: DateTime.now(),
      contents: contents,
    );
  }

  factory ChatMessage.assistant({
    String? text,
    String? imageUrl,
    String? codeSnippet,
  }) {
    final List<MessageContent> contents = [];
    
    if (text != null && text.isNotEmpty) {
      contents.add(MessageContent(type: MessageContentType.text, content: text));
    }
    
    if (imageUrl != null) {
      contents.add(MessageContent(type: MessageContentType.image, content: imageUrl));
    }
    
    if (codeSnippet != null) {
      contents.add(MessageContent(
        type: MessageContentType.code, 
        content: codeSnippet,
        metadata: {'language': 'dart'}, // Default language
      ));
    }
    
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: MessageRole.assistant,
      timestamp: DateTime.now(),
      contents: contents,
    );
  }

  @override
  List<Object?> get props => [id, role, timestamp, contents];
}

class MessageContent extends Equatable {
  final MessageContentType type;
  final String content;
  final Map<String, dynamic>? metadata;

  const MessageContent({
    required this.type,
    required this.content,
    this.metadata,
  });

  @override
  List<Object?> get props => [type, content, metadata];
}
