import 'package:ai_chat_app/features/chat/data/models/chat_message.dart';
import 'package:ai_chat_app/features/chat/domain/repositories/chat_repository.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';

// Events
abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

class LoginEvent extends ChatEvent {
  final String username;
  final String password;

  const LoginEvent({required this.username, required this.password});

  @override
  List<Object?> get props => [username, password];
}

class FetchChatsEvent extends ChatEvent {}

class CreateChatEvent extends ChatEvent {
  final String title;

  const CreateChatEvent({required this.title});

  @override
  List<Object?> get props => [title];
}

class FetchMessagesEvent extends ChatEvent {
  final String chatId;

  const FetchMessagesEvent({required this.chatId});

  @override
  List<Object?> get props => [chatId];
}

class SendMessageEvent extends ChatEvent {
  final String chatId;
  final String content;

  const SendMessageEvent({required this.chatId, required this.content});

  @override
  List<Object?> get props => [chatId, content];
}

// States
abstract class ChatState extends Equatable {
  const ChatState();

  @override
  List<Object?> get props => [];
}

class ChatInitial extends ChatState {}

class ChatLoading extends ChatState {}

class ChatLoginSuccess extends ChatState {}

class ChatLoginFailure extends ChatState {
  final String error;

  const ChatLoginFailure({required this.error});

  @override
  List<Object?> get props => [error];
}

class ChatsLoaded extends ChatState {
  final List<Map<String, dynamic>> chats;

  const ChatsLoaded({required this.chats});

  @override
  List<Object?> get props => [chats];
}

class ChatsLoadFailure extends ChatState {
  final String error;

  const ChatsLoadFailure({required this.error});

  @override
  List<Object?> get props => [error];
}

class MessagesLoaded extends ChatState {
  final List<Map<String, dynamic>> messages;

  const MessagesLoaded({required this.messages});

  @override
  List<Object?> get props => [messages];
}

class MessagesLoadFailure extends ChatState {
  final String error;

  const MessagesLoadFailure({required this.error});

  @override
  List<Object?> get props => [error];
}

class MessageSent extends ChatState {
  final ChatMessage message;

  const MessageSent({required this.message});

  @override
  List<Object?> get props => [message];
}

class MessageSendFailure extends ChatState {
  final String error;

  const MessageSendFailure({required this.error});

  @override
  List<Object?> get props => [error];
}

// BLoC
@injectable
class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatRepository repository;

  ChatBloc({required this.repository}) : super(ChatInitial()) {
    on<LoginEvent>(_onLogin);
    on<FetchChatsEvent>(_onFetchChats);
    on<CreateChatEvent>(_onCreateChat);
    on<FetchMessagesEvent>(_onFetchMessages);
    on<SendMessageEvent>(_onSendMessage);
  }

  Future<void> _onLogin(LoginEvent event, Emitter<ChatState> emit) async {
    emit(ChatLoading());
    final result = await repository.login(event.username, event.password);
    result.fold(
      (error) => emit(ChatLoginFailure(error: error)),
      (success) => emit(ChatLoginSuccess()),
    );
  }

  Future<void> _onFetchChats(FetchChatsEvent event, Emitter<ChatState> emit) async {
    emit(ChatLoading());
    final result = await repository.getChats();
    result.fold(
      (error) => emit(ChatsLoadFailure(error: error)),
      (chats) => emit(ChatsLoaded(chats: chats)),
    );
  }

  Future<void> _onCreateChat(CreateChatEvent event, Emitter<ChatState> emit) async {
    emit(ChatLoading());
    final result = await repository.createChat(event.title);
    result.fold(
      (error) => emit(ChatsLoadFailure(error: error)),
      (_) => add(FetchChatsEvent()),
    );
  }

  Future<void> _onFetchMessages(FetchMessagesEvent event, Emitter<ChatState> emit) async {
    emit(ChatLoading());
    final result = await repository.getMessages(event.chatId);
    result.fold(
      (error) => emit(MessagesLoadFailure(error: error)),
      (messages) => emit(MessagesLoaded(messages: messages)),
    );
  }

  Future<void> _onSendMessage(SendMessageEvent event, Emitter<ChatState> emit) async {
    final result = await repository.sendMessage(event.chatId, event.content);
    result.fold(
      (error) => emit(MessageSendFailure(error: error)),
      (message) {
        if (message != null) {
          emit(MessageSent(message: message));
        }
        add(FetchMessagesEvent(chatId: event.chatId));
      },
    );
  }
}
