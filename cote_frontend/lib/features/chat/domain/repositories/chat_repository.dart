import 'package:ai_chat_app/features/chat/data/models/chat_message.dart';
import 'package:dartz/dartz.dart';

abstract class ChatRepository {
  Future<Either<String, bool>> login(String username, String password);
  Future<Either<String, List<Map<String, dynamic>>>> getChats();
  Future<Either<String, Map<String, dynamic>?>> createChat(String title);
  Future<Either<String, List<Map<String, dynamic>>>> getMessages(String chatId);
  Future<Either<String, ChatMessage?>> sendMessage(String chatId, String content);
}
