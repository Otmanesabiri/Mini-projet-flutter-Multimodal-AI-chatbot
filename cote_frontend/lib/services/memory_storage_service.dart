import '../models/conversation.dart';
import '../models/message.dart';

/// Service de stockage en mémoire simple (sans persistance)
class MemoryStorageService {
  static final List<Conversation> _conversations = [];
  static Conversation? _currentConversation;

  /// Initialiser le service
  static Future<void> init() async {
    // Rien à faire pour le stockage en mémoire
  }

  /// Créer une nouvelle conversation
  static Conversation createNewConversation({String? title}) {
    final conversation = Conversation.create(title: title);
    _conversations.add(conversation);
    _currentConversation = conversation;
    return conversation;
  }

  /// Obtenir toutes les conversations
  static List<Conversation> getAllConversations() {
    return List.from(_conversations)
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  /// Obtenir une conversation par ID
  static Conversation? getConversation(String id) {
    try {
      return _conversations.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Obtenir la conversation actuelle
  static Conversation? getCurrentConversation() {
    return _currentConversation;
  }

  /// Définir la conversation actuelle
  static void setCurrentConversation(Conversation? conversation) {
    _currentConversation = conversation;
  }

  /// Ajouter un message à une conversation
  static void addMessageToConversation(String conversationId, ChatMessage message) {
    final conversation = getConversation(conversationId);
    if (conversation != null) {
      conversation.addMessage(message);
      
      // Mettre à jour la conversation dans la liste
      final index = _conversations.indexWhere((c) => c.id == conversationId);
      if (index != -1) {
        _conversations[index] = conversation.copyWith(
          updatedAt: DateTime.now(),
        );
      }
    }
  }

  /// Mettre à jour le titre d'une conversation
  static void updateConversationTitle(String id, String title) {
    final index = _conversations.indexWhere((c) => c.id == id);
    if (index != -1) {
      _conversations[index] = _conversations[index].copyWith(
        title: title,
        updatedAt: DateTime.now(),
      );
      
      // Mettre à jour la conversation actuelle si c'est celle-ci
      if (_currentConversation?.id == id) {
        _currentConversation = _conversations[index];
      }
    }
  }

  /// Supprimer une conversation
  static void deleteConversation(String id) {
    _conversations.removeWhere((c) => c.id == id);
    
    // Si c'était la conversation actuelle, la réinitialiser
    if (_currentConversation?.id == id) {
      _currentConversation = null;
    }
  }

  /// Supprimer toutes les conversations
  static void clearAllConversations() {
    _conversations.clear();
    _currentConversation = null;
  }

  /// Rechercher des conversations par titre ou contenu
  static List<Conversation> searchConversations(String query) {
    final lowercaseQuery = query.toLowerCase();
    return _conversations.where((conversation) {
      // Recherche dans le titre
      if (conversation.title.toLowerCase().contains(lowercaseQuery)) {
        return true;
      }
      
      // Recherche dans le contenu des messages
      return conversation.messages.any((message) =>
          message.content.toLowerCase().contains(lowercaseQuery));
    }).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  /// Obtenir des statistiques simples
  static Map<String, dynamic> getStats() {
    final totalMessages = _conversations.fold<int>(
      0,
      (sum, conversation) => sum + conversation.messages.length,
    );

    return {
      'totalConversations': _conversations.length,
      'totalMessages': totalMessages,
      'currentConversation': _currentConversation?.id,
    };
  }

  /// Fermer le service (rien à faire)
  static Future<void> close() async {
    // Rien à faire pour le stockage en mémoire
  }
}
