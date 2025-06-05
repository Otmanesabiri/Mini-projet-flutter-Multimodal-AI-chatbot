import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/deepseek_service.dart';
import '../services/memory_storage_service.dart';
import '../models/message.dart';
import '../models/conversation.dart';

class ChatbotPage extends StatefulWidget {
  const ChatbotPage({super.key});

  @override
  State<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final DeepSeekService _deepSeekService = DeepSeekService();
  final ImagePicker _imagePicker = ImagePicker();
  
  bool _isLoading = false;
  File? _selectedImage;
  Conversation? _currentConversation;

  @override
  void initState() {
    super.initState();
    _initializeConversation();
  }

  Future<void> _initializeConversation() async {
    // Créer une nouvelle conversation ou charger la dernière
    final conversations = MemoryStorageService.getAllConversations();
    if (conversations.isNotEmpty) {
      _currentConversation = conversations.first; // Dernière conversation
      setState(() {
        _messages.clear();
        _messages.addAll(_currentConversation!.messages);
      });
    } else {
      _currentConversation = MemoryStorageService.createNewConversation();
      _addWelcomeMessage();
    }
  }

  void _addWelcomeMessage() {
    final welcomeMessage = ChatMessage(
      role: 'assistant',
      content: 'Bonjour ! Je suis votre assistant IA multimodal. Comment puis-je vous aider aujourd\'hui ?',
      timestamp: DateTime.now(),
    );
    
    setState(() {
      _messages.add(welcomeMessage);
    });
    
    // Sauvegarder dans la conversation actuelle
    if (_currentConversation != null) {
      _currentConversation!.addMessage(welcomeMessage);
      // Pas besoin de sauvegarder avec MemoryStorageService
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty && _selectedImage == null) return;

    // Ajouter le message de l'utilisateur
    final userMessage = ChatMessage.withImage(
      role: 'user',
      content: text.isNotEmpty ? text : 'Image envoyée',
      timestamp: DateTime.now(),
      image: _selectedImage,
    );

    setState(() {
      _messages.add(userMessage);
      _isLoading = true;
    });

    // Sauvegarder le message de l'utilisateur
    if (_currentConversation != null) {
      _currentConversation!.addMessage(userMessage);
      MemoryStorageService.addMessageToConversation(_currentConversation!.id, userMessage);
    }

    _messageController.clear();
    _selectedImage = null;
    _scrollToBottom();

    try {
      // Préparer l'historique des messages pour l'API
      final messageHistory = _messages
          .where((msg) => msg.image == null) // Pour l'instant, on n'envoie que le texte
          .map((msg) => {
            'role': msg.role,
            'content': msg.content,
          })
          .toList();

      // Appeler l'API DeepSeek
      final response = await _deepSeekService.sendMessage(messageHistory);

      // Ajouter la réponse de l'assistant
      final assistantMessage = ChatMessage(
        role: 'assistant',
        content: response,
        timestamp: DateTime.now(),
      );

      setState(() {
        _messages.add(assistantMessage);
        _isLoading = false;
      });

      // Sauvegarder la réponse de l'assistant
      if (_currentConversation != null) {
        _currentConversation!.addMessage(assistantMessage);
        MemoryStorageService.addMessageToConversation(_currentConversation!.id, assistantMessage);
      }
    } catch (e) {
      final errorMessage = ChatMessage(
        role: 'assistant',
        content: 'Désolé, une erreur s\'est produite. Veuillez réessayer.',
        timestamp: DateTime.now(),
      );

      setState(() {
        _messages.add(errorMessage);
        _isLoading = false;
      });

      // Sauvegarder le message d'erreur
      if (_currentConversation != null) {
        _currentConversation!.addMessage(errorMessage);
        MemoryStorageService.addMessageToConversation(_currentConversation!.id, errorMessage);
      }
    }

    _scrollToBottom();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // Gestion des conversations
  Future<void> _createNewConversation() async {
    _currentConversation = MemoryStorageService.createNewConversation();
    setState(() {
      _messages.clear();
    });
    _addWelcomeMessage();
  }

  Future<void> _showConversationsList() async {
    final conversations = MemoryStorageService.getAllConversations();
    if (conversations.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucune conversation sauvegardée')),
      );
      return;
    }

    final selectedConversation = await showDialog<Conversation>(
      context: context,
      builder: (context) => _ConversationsListDialog(conversations: conversations),
    );

    if (selectedConversation != null) {
      _currentConversation = selectedConversation;
      setState(() {
        _messages.clear();
        _messages.addAll(_currentConversation!.messages);
      });
      _scrollToBottom();
    }
  }

  Future<void> _clearCurrentConversation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Effacer conversation'),
        content: const Text('Êtes-vous sûr de vouloir effacer cette conversation ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Effacer'),
          ),
        ],
      ),
    );

    if (confirmed == true && _currentConversation != null) {
      MemoryStorageService.deleteConversation(_currentConversation!.id);
      _createNewConversation();
    }
  }

  Future<void> _clearAllConversations() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Effacer tout l\'historique'),
        content: const Text('Êtes-vous sûr de vouloir effacer toutes les conversations ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Tout effacer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      MemoryStorageService.clearAllConversations();
      _createNewConversation();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentConversation?.title ?? 'AI Chatbot Multimodal'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'new_conversation':
                  _createNewConversation();
                  break;
                case 'conversations_list':
                  _showConversationsList();
                  break;
                case 'clear_current':
                  _clearCurrentConversation();
                  break;
                case 'clear_all':
                  _clearAllConversations();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'new_conversation',
                child: Row(
                  children: [
                    Icon(Icons.add),
                    SizedBox(width: 8),
                    Text('Nouvelle conversation'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'conversations_list',
                child: Row(
                  children: [
                    Icon(Icons.history),
                    SizedBox(width: 8),
                    Text('Historique'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear_current',
                child: Row(
                  children: [
                    Icon(Icons.clear),
                    SizedBox(width: 8),
                    Text('Effacer conversation'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear_all',
                child: Row(
                  children: [
                    Icon(Icons.delete_forever),
                    SizedBox(width: 8),
                    Text('Tout effacer'),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/',
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Liste des messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isLoading) {
                  return _buildLoadingIndicator();
                }
                return _buildMessageBubble(_messages[index]);
              },
            ),
          ),
          
          // Zone de saisie
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.role == 'user';
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            const CircleAvatar(
              radius: 16,
              backgroundColor: Colors.blue,
              child: Icon(Icons.smart_toy, size: 16, color: Colors.white),
            ),
            const SizedBox(width: 8),
          ],
          
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? Colors.blue : Colors.grey[200],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.image != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        message.image!,
                        width: 200,
                        height: 150,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Text(
                    message.content,
                    style: TextStyle(
                      color: isUser ? Colors.white : Colors.black87,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      color: isUser ? Colors.white70 : Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          if (isUser) ...[
            const SizedBox(width: 8),
            const CircleAvatar(
              radius: 16,
              backgroundColor: Colors.green,
              child: Icon(Icons.person, size: 16, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const CircleAvatar(
            radius: 16,
            backgroundColor: Colors.blue,
            child: Icon(Icons.smart_toy, size: 16, color: Colors.white),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 8),
                Text('En train de réfléchir...'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, -2),
            blurRadius: 4,
            color: Colors.black.withValues(alpha: 0.1),
          ),
        ],
      ),
      child: Column(
        children: [
          if (_selectedImage != null) ...[
            Container(
              height: 100,
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      _selectedImage!,
                      width: double.infinity,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedImage = null),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          Row(
            children: [
              IconButton(
                onPressed: _pickImage,
                icon: const Icon(Icons.image),
                color: Colors.blue,
              ),
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: const InputDecoration(
                    hintText: 'Tapez votre message...',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  maxLines: null,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 8),
              FloatingActionButton(
                onPressed: _isLoading ? null : _sendMessage,
                mini: true,
                child: _isLoading 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

// Widget pour afficher la liste des conversations
class _ConversationsListDialog extends StatelessWidget {
  final List<Conversation> conversations;

  const _ConversationsListDialog({required this.conversations});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Historique des conversations'),
      content: SizedBox(
        width: double.maxFinite,
        height: 300,
        child: ListView.builder(
          itemCount: conversations.length,
          itemBuilder: (context, index) {
            final conversation = conversations[index];
            final messageCount = conversation.messages.length;
            final lastMessage = messageCount > 0 
                ? conversation.messages.last.content
                : 'Conversation vide';
            
            return ListTile(
              title: Text(
                conversation.title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lastMessage.length > 50 
                        ? '${lastMessage.substring(0, 50)}...'
                        : lastMessage,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_formatDate(conversation.updatedAt)} • $messageCount messages',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              onTap: () => Navigator.pop(context, conversation),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Fermer'),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}j';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}min';
    } else {
      return 'Maintenant';
    }
  }
}
