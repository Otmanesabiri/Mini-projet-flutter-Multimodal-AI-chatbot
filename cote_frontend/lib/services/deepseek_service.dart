import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class DeepSeekService {
  late final Dio _dio;
  static const String baseUrl = 'http://localhost:8088'; // URL de notre backend FastAPI
  
  // Cache local simple pour éviter les requêtes redondantes
  final Map<String, String> _localCache = {};
  static const int maxCacheSize = 50;

  DeepSeekService() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15), // Réduire le timeout de connexion
      receiveTimeout: const Duration(seconds: 30), // Réduire le timeout de réception
      headers: {
        'Content-Type': 'application/json',
      },
    ));

    // Ajouter un intercepteur pour le logging en mode debug
    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: false, // Désactiver pour de meilleures performances
        responseBody: false,
        requestHeader: false,
        responseHeader: false,
      ));
    }
  }

  /// Créer une clé de cache simple basée sur le dernier message
  String _createCacheKey(List<Map<String, String>> messages) {
    if (messages.isEmpty) return '';
    final lastMessage = messages.last;
    return '${lastMessage['role']}_${lastMessage['content']?.hashCode}';
  }

  /// Optimiser les messages pour réduire les tokens
  List<Map<String, String>> _optimizeMessages(List<Map<String, String>> messages) {
    // Garder seulement les 8 derniers messages pour réduire la latence
    if (messages.length > 8) {
      return messages.sublist(messages.length - 8);
    }
    return messages;
  }

  /// Ajouter une réponse au cache local avec gestion de la taille
  void _addToCache(String key, String content) {
    // Si le cache est plein, supprimer l'entrée la plus ancienne
    if (_localCache.length >= maxCacheSize) {
      final firstKey = _localCache.keys.first;
      _localCache.remove(firstKey);
      debugPrint('Cache plein: suppression de l\'entrée $firstKey');
    }
    
    _localCache[key] = content;
    debugPrint('Ajout au cache: ${_localCache.length}/$maxCacheSize entrées');
  }

  /// Vider le cache local
  void clearCache() {
    _localCache.clear();
    debugPrint('Cache local vidé');
  }

  /// Obtenir les statistiques du cache
  Map<String, dynamic> getCacheStats() {
    return {
      'entries': _localCache.length,
      'maxSize': maxCacheSize,
      'usagePercent': (_localCache.length / maxCacheSize * 100).toStringAsFixed(1),
    };
  }

  /// Envoie un message à l'API DeepSeek via notre backend avec optimisations
  Future<String> sendMessage(List<Map<String, String>> messages, {
    bool useCache = true,
    double temperature = 0.3, // Plus bas pour de meilleures performances
    int maxTokens = 512, // Limiter pour la rapidité
  }) async {
    try {
      // Optimiser les messages
      final optimizedMessages = _optimizeMessages(messages);
      debugPrint('Messages optimisés: ${optimizedMessages.length} (de ${messages.length})');
      
      // Vérifier le cache local
      if (useCache) {
        final cacheKey = _createCacheKey(optimizedMessages);
        if (_localCache.containsKey(cacheKey)) {
          debugPrint('Réponse récupérée du cache local');
          return _localCache[cacheKey]!;
        }
      }
      
      final response = await _dio.post(
        '/v1/chat/completions',
        data: {
          'model': 'deepseek-chat',
          'messages': optimizedMessages,
          'temperature': temperature,
          'max_tokens': maxTokens,
          'top_p': 0.8,
          'frequency_penalty': 0.1,
          'presence_penalty': 0.1,
          'stream': false,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final content = data['content'];
        final usage = data['usage'];
        
        debugPrint('Réponse reçue: ${content.length} caractères');
        debugPrint('Tokens utilisés: ${usage['total_tokens']}');
        
        // Mettre en cache la réponse
        if (useCache) {
          final cacheKey = _createCacheKey(optimizedMessages);
          _addToCache(cacheKey, content);
        }
        
        return content;
      } else {
        throw Exception('Erreur HTTP: ${response.statusCode}');
      }
    } on DioException catch (e) {
      debugPrint('Erreur Dio: ${e.message}');
      
      if (e.type == DioExceptionType.connectionTimeout) {
        throw Exception('Délai de connexion dépassé. Vérifiez que le serveur est démarré.');
      } else if (e.type == DioExceptionType.receiveTimeout) {
        throw Exception('Délai de réponse dépassé. Le serveur met trop de temps à répondre.');
      } else if (e.response != null) {
        final errorMessage = e.response?.data?['detail'] ?? e.message;
        throw Exception('Erreur du serveur: $errorMessage');
      } else {
        throw Exception('Erreur de connexion: ${e.message}');
      }
    } catch (e) {
      debugPrint('Erreur inattendue: $e');
      throw Exception('Une erreur inattendue s\'est produite: $e');
    }
  }

  /// Teste la connexion avec le backend
  Future<bool> testConnection() async {
    try {
      final response = await _dio.get('/');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Test de connexion échoué: $e');
      return false;
    }
  }

  /// Obtient le statut du service
  Future<Map<String, dynamic>?> getServiceStatus() async {
    try {
      final response = await _dio.get('/');
      return response.data;
    } catch (e) {
      debugPrint('Impossible d\'obtenir le statut du service: $e');
      return null;
    }
  }
}
