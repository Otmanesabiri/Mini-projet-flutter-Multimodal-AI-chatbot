import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class DeepSeekService {
  late final Dio _dio;
  static const String baseUrl = 'http://localhost:8088'; // URL de notre backend FastAPI

  DeepSeekService() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60),
      headers: {
        'Content-Type': 'application/json',
      },
    ));

    // Ajouter un intercepteur pour le logging en mode debug
    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
      ));
    }
  }

  /// Envoie un message à l'API DeepSeek via notre backend
  Future<String> sendMessage(List<Map<String, String>> messages) async {
    try {
      debugPrint('Envoi de ${messages.length} messages à DeepSeek');
      
      final response = await _dio.post(
        '/v1/chat/completions',
        data: {
          'model': 'deepseek-chat',
          'messages': messages,
          'temperature': 0.7,
          'stream': false,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final content = data['content'];
        
        debugPrint('Réponse reçue: ${content.length} caractères');
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
