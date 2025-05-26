import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

@lazySingleton // Added injectable annotation
class ChatApiService {
  final Dio _dio;
  final String baseUrl;

  // Constructor now takes baseUrl, which will be injected.
  // Dio instance is created internally, or could also be injected if registered.
  ChatApiService(@Named('baseUrl') this.baseUrl) : _dio = Dio();

  Future<String> login(String username, String password) async {
    final response = await _dio.post(
      '$baseUrl/token', // Uses the injected baseUrl
      data: {
        'username': username,
        'password': password,
      },
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );
    return response.data['access_token'];
  }

  Future<List<dynamic>> getChats(String token) async {
    final response = await _dio.get(
      '$baseUrl/chats/', // Uses the injected baseUrl
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return response.data;
  }

  Future<Map<String, dynamic>> createChat(String token, String title) async {
    final response = await _dio.post(
      '$baseUrl/chats/', // Uses the injected baseUrl
      data: {'title': title},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return response.data;
  }

  Future<List<dynamic>> getMessages(String token, String chatId) async {
    final response = await _dio.get(
      '$baseUrl/chats/$chatId/messages/', // Uses the injected baseUrl
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return response.data;
  }

  Future<Map<String, dynamic>> sendMessage(
      String token, String chatId, String content) async {
    final response = await _dio.post(
      '$baseUrl/chats/$chatId/messages/', // Uses the injected baseUrl
      data: {'content': content},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return response.data;
  }
}
