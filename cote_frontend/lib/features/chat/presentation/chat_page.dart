import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ai_chat_app/features/chat/data/models/chat_message.dart';
import 'package:ai_chat_app/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:ai_chat_app/features/chat/presentation/widgets/message_bubble.dart';
import 'package:ai_chat_app/injection.dart';

class ChatPage extends StatefulWidget {
  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late ChatBloc _chatBloc;
  String _currentChatId = '';
  String _currentChatTitle = '';
  List<Map<String, dynamic>> _chats = [];
  List<Map<String, dynamic>> _messages = [];
  bool _isCreatingChat = false;
  final _newChatController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _chatBloc = getIt<ChatBloc>();
    _loadChats();
  }

  void _loadChats() {
    setState(() => _isLoading = true);
    _chatBloc.add(FetchChatsEvent());
  }

  @override
  void dispose() {
    _messageController.dispose();
    _newChatController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isNotEmpty && _currentChatId.isNotEmpty) {
      _chatBloc.add(SendMessageEvent(
        chatId: _currentChatId,
        content: message,
      ));
      _messageController.clear();
      
      // Add temporary message to list while waiting for API response
      setState(() {
        _messages.add({
          'id': 'temp_${DateTime.now().millisecondsSinceEpoch}',
          'content': message,
          'type': 'text',
          'sender': 'user',
          'timestamp': DateTime.now().toIso8601String(),
        });
      });
      
      // Scroll to show new message
      Future.delayed(Duration(milliseconds: 100), _scrollToBottom);
    } else if (_currentChatId.isEmpty) {
      _promptCreateChat();
    }
  }

  void _promptCreateChat() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Create a new chat'),
        content: TextField(
          controller: _newChatController,
          decoration: InputDecoration(
            hintText: 'Enter chat title',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_newChatController.text.trim().isNotEmpty) {
                _createChat(_newChatController.text.trim());
                _newChatController.clear();
                Navigator.of(context).pop();
              }
            },
            child: Text('Create'),
          ),
        ],
      ),
    );
  }

  void _createChat(String title) {
    _chatBloc.add(CreateChatEvent(title: title));
    setState(() => _isLoading = true);
  }

  void _selectChat(String chatId, String title) {
    setState(() {
      _currentChatId = chatId;
      _currentChatTitle = title;
      _messages = []; // Clear messages when switching chats
      _isLoading = true;
    });
    _chatBloc.add(FetchMessagesEvent(chatId: chatId));
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => _chatBloc,
      child: BlocListener<ChatBloc, ChatState>(
        listener: (context, state) {
          if (state is ChatsLoaded) {
            setState(() {
              _chats = state.chats;
              _isLoading = false;
              
              // Select first chat automatically if none selected
              if (_chats.isNotEmpty && _currentChatId.isEmpty) {
                _currentChatId = _chats.first['id'];
                _currentChatTitle = _chats.first['title'];
                _chatBloc.add(FetchMessagesEvent(chatId: _currentChatId));
              }
            });
          } else if (state is MessagesLoaded) {
            setState(() {
              _messages = state.messages;
              _isLoading = false;
            });
            // Scroll to bottom when messages are loaded
            Future.delayed(Duration(milliseconds: 100), _scrollToBottom);
          } else if (state is MessageSent) {
            // Refresh messages after sending
            if (_currentChatId.isNotEmpty) {
              _chatBloc.add(FetchMessagesEvent(chatId: _currentChatId));
            }
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: Text(_currentChatTitle.isEmpty ? 'AI Chat' : _currentChatTitle),
            actions: [
              IconButton(
                icon: Icon(Icons.refresh),
                onPressed: () {
                  if (_currentChatId.isNotEmpty) {
                    _chatBloc.add(FetchMessagesEvent(chatId: _currentChatId));
                  } else {
                    _loadChats();
                  }
                },
              ),
            ],
          ),
          drawer: Drawer(
            child: Column(
              children: [
                DrawerHeader(
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                  ),
                  child: Center(
                    child: Text(
                      'AI Chat App',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton.icon(
                    onPressed: _promptCreateChat,
                    icon: Icon(Icons.add),
                    label: Text('New Chat'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(double.infinity, 40),
                    ),
                  ),
                ),
                Divider(),
                Expanded(
                  child: _isLoading && _chats.isEmpty
                      ? Center(child: CircularProgressIndicator())
                      : ListView.builder(
                          itemCount: _chats.length,
                          itemBuilder: (context, index) {
                            final chat = _chats[index];
                            final isSelected = chat['id'] == _currentChatId;
                            final lastMessage = chat['last_message_content'] ?? '';
                            
                            return ListTile(
                              title: Text(
                                chat['title'] ?? 'Unnamed Chat',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: lastMessage.isNotEmpty
                                  ? Text(
                                      lastMessage,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    )
                                  : Text('No messages yet'),
                              selected: isSelected,
                              tileColor: isSelected ? Colors.blue.withOpacity(0.1) : null,
                              onTap: () {
                                _selectChat(chat['id'], chat['title']);
                                Navigator.pop(context); // Close drawer
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          body: Column(
            children: [
              // Messages list
              Expanded(
                child: _currentChatId.isEmpty
                    ? Center(child: Text('Select or create a chat to start messaging'))
                    : _isLoading && _messages.isEmpty
                        ? Center(child: CircularProgressIndicator())
                        : ListView.builder(
                            controller: _scrollController,
                            reverse: true,
                            padding: EdgeInsets.all(16),
                            itemCount: _messages.length,
                            itemBuilder: (context, index) {
                              final reversedIndex = _messages.length - 1 - index;
                              final message = _messages[reversedIndex];
                              final isUser = message['sender'] == 'user';
                              
                              // Convert to message format for bubble
                              final chatMessage = ChatMessage(
                                id: message['id'] ?? '',
                                role: isUser ? MessageRole.user : MessageRole.assistant,
                                timestamp: DateTime.parse(message['timestamp']),
                                contents: [
                                  MessageContent(
                                    type: MessageContentType.text,
                                    content: message['content'] ?? '',
                                  ),
                                ],
                              );
                              
                              return MessageBubble(
                                message: chatMessage,
                                isUser: isUser,
                              );
                            },
                          ),
              ),
              // Message input
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 3,
                      offset: Offset(0, -1),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.attach_file),
                      onPressed: () {
                        // Will implement file attachment later
                      },
                    ),
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.grey[200],
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                        maxLines: null,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.send),
                      onPressed: _sendMessage,
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
}
