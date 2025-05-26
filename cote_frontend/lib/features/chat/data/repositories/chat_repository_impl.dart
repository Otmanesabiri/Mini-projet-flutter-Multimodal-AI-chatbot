import 'package:ai_chat_app/features/chat/data/datasources/chat_api_service.dart';
import 'package:ai_chat_app/features/chat/data/models/chat_message.dart';
import 'package:ai_chat_app/features/chat/domain/repositories/chat_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: ChatRepository)
class ChatRepositoryImpl implements ChatRepository {
  final ChatApiService apiService;

  ChatRepositoryImpl({required this.apiService});

  @override
  Future<Either<String, bool>> login(String username, String password) async {
    try {
      final result = await apiService.login(username, password);
      return Right(result);
    } catch (e) {
      return Left('Login failed: ${e.toString()}');
    }
  }

  @override
  Future<Either<String, List<Map<String, dynamic>>>> getChats() async {
    try {
      final chats = await apiService.getChats();
      return Right(chats);
    } catch (e) {
      return Left('Failed to fetch chats: ${e.toString()}');
    }
  }

  @override
  Future<Either<String, Map<String, dynamic>?>> createChat(String title) async {
    try {
      final chat = await apiService.createChat(title);
      return Right(chat);
    } catch (e) {
      return Left('Failed to create chat: ${e.toString()}');
    }
  }

  @override
  Future<Either<String, List<Map<String, dynamic>>>> getMessages(String chatId) async {
    try {
      final messages = await apiService.getMessages(chatId);
      return Right(messages);
    } catch (e) {
      return Left('Failed to fetch messages: ${e.toString()}');
    }
  }

  @override
  Future<Either<String, ChatMessage?>> sendMessage(String chatId, String content) async {
    try {
      final response = await apiService.sendMessage(chatId, content);
      if (response != null) {
        // Convert the API response to a ChatMessage object
        final message = ChatMessage.user(text: content);
        return Right(message);
      }
      return const Right(null);
    } catch (e) {
      return Left('Failed to send message: ${e.toString()}');
    }
  }
}
