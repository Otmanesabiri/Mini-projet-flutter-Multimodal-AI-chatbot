import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

@lazySingleton
class ChatApiService {
  final Dio _dio;
  final String baseUrl;
  String? _authToken;

  // Modified constructor to work with both direct and DI instantiation
  ChatApiService({@Named('baseUrl') required this.baseUrl}) : _dio = Dio() {
    // Initialize Dio with interceptors for logging, etc.
    _dio.interceptors.add(LogInterceptor(
      requestHeader: true,
      requestBody: true,
      responseHeader: true,
      responseBody: true,
      error: true,
      logPrint: (object) => print(object.toString()),
    ));
  }

  // Authentication methods
  Future<bool> login(String username, String password) async {
    try {
      final response = await _dio.post(
        '$baseUrl/token',
        data: {
          'username': username,
          'password': password,
        },
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );

      _authToken = response.data['access_token'];

      // Save token to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', _authToken!);

      return true;
    } catch (e) {
      print('Login error: $e');
      return false;
    }
  }

  // Chat methods
  Future<List<Map<String, dynamic>>> getChats() async {
    await _ensureAuthToken();

    try {
      final response = await _dio.get(
        '$baseUrl/chats/',
        options: Options(headers: {'Authorization': 'Bearer $_authToken'}),
      );

      // Handle different backends (app.py vs cote_backend/main.py)
      if (response.data is List) {
        return List<Map<String, dynamic>>.from(response.data);
      } else if (response.data is Map && response.data.containsKey('data')) {
        return List<Map<String, dynamic>>.from(response.data['data']);
      } else {
        return [];
      }
    } catch (e) {
      print('Error fetching chats: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> createChat(String title) async {
    await _ensureAuthToken();

    try {
      final response = await _dio.post(
        '$baseUrl/chats/',
        data: {'title': title},
        options: Options(headers: {'Authorization': 'Bearer $_authToken'}),
      );

      if (response.data is Map) {
        return response.data.containsKey('data')
            ? Map<String, dynamic>.from(response.data['data'])
            : Map<String, dynamic>.from(response.data);
      }
      return null;
    } catch (e) {
      print('Error creating chat: $e');
      return null;
    }
  }

  // Message methods
  Future<List<Map<String, dynamic>>> getMessages(String chatId) async {
    await _ensureAuthToken();

    try {
      final response = await _dio.get(
        '$baseUrl/chats/$chatId/messages/',
        options: Options(headers: {'Authorization': 'Bearer $_authToken'}),
      );

      // Handle different backends (app.py vs cote_backend/main.py)
      if (response.data is List) {
        return List<Map<String, dynamic>>.from(response.data);
      } else if (response.data is Map && response.data.containsKey('data')) {
        return List<Map<String, dynamic>>.from(response.data['data']);
      } else {
        return [];
      }
    } catch (e) {
      print('Error fetching messages: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> sendMessage(String chatId, String content) async {
    await _ensureAuthToken();

    try {
      final response = await _dio.post(
        '$baseUrl/chats/$chatId/messages/',
        data: {'content': content, 'type': 'text'},
        options: Options(headers: {'Authorization': 'Bearer $_authToken'}),
      );

      if (response.data is Map) {
        return response.data.containsKey('data')
            ? Map<String, dynamic>.from(response.data['data'])
            : Map<String, dynamic>.from(response.data);
      }
      return null;
    } catch (e) {
      print('Error sending message: $e');
      return null;
    }
  }

  // Helper methods
  Future<void> _ensureAuthToken() async {
    if (_authToken == null) {
      final prefs = await SharedPreferences.getInstance();
      _authToken = prefs.getString('auth_token');

      if (_authToken == null) {
        throw Exception('User not logged in');
      }
    }
  }
}
