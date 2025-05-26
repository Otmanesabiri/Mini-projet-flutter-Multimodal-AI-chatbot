import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:ai_chat_app/features/chat/data/models/chat_message.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isUser;

  const MessageBubble({
    Key? key,
    required this.message,
    required this.isUser,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          decoration: BoxDecoration(
            color: isUser ? Colors.blue : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var content in message.contents)
                _buildContentWidget(content, context),
              
              Padding(
                padding: const EdgeInsets.only(right: 8, bottom: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      _formatTime(message.timestamp),
                      style: TextStyle(
                        fontSize: 10,
                        color: isUser ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContentWidget(MessageContent content, BuildContext context) {
    switch (content.type) {
      case MessageContentType.text:
        return Padding(
          padding: const EdgeInsets.all(12.0),
          child: MarkdownBody(
            data: content.content,
            styleSheet: MarkdownStyleSheet(
              p: TextStyle(
                color: isUser ? Colors.white : Colors.black,
                fontSize: 16,
              ),
              code: TextStyle(
                backgroundColor: Colors.grey.shade700,
                color: Colors.white,
                fontSize: 14,
              ),
            ),
            onTapLink: (text, href, title) {
              // Handle link taps
            },
          ),
        );
        
      case MessageContentType.image:
        return Container(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              content.content,
              fit: BoxFit.contain,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                );
              },
            ),
          ),
        );
        
      case MessageContentType.code:
        return Container(
          margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      content.metadata?['language'] ?? 'code',
                      style: TextStyle(color: Colors.white70),
                    ),
                    IconButton(
                      icon: Icon(Icons.copy, color: Colors.white),
                      iconSize: 16,
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: content.content));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Code copied to clipboard')),
                        );
                      },
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Text(
                    content.content,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      color: Colors.greenAccent,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
        
      default:
        return SizedBox.shrink();
    }
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(
        timestamp.year, timestamp.month, timestamp.day);

    if (messageDate == today) {
      // Today, show time only
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else {
      // Not today, show date and time
      return '${timestamp.day}/${timestamp.month} ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }
}
