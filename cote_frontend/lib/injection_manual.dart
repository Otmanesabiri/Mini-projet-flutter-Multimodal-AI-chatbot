import 'package:get_it/get_it.dart';
import 'package:ai_chat_app/features/chat/data/datasources/chat_api_service.dart';
import 'package:ai_chat_app/features/chat/domain/repositories/chat_repository.dart';
import 'package:ai_chat_app/features/chat/data/repositories/chat_repository_impl.dart';
import 'package:ai_chat_app/features/chat/presentation/bloc/chat_bloc.dart';
import 'package:ai_chat_app/main.dart';

// Manual implementation of dependency injection
void $initGetIt(GetIt sl) {
  // Register the baseUrl first
  sl.registerLazySingleton<String>(
    () => MyApp.apiBaseUrl,
    instanceName: 'baseUrl',
  );
  
  // Services - API
  sl.registerLazySingleton<ChatApiService>(
    () => ChatApiService(baseUrl: sl<String>(instanceName: 'baseUrl')),
  );
  
  // Repositories
  sl.registerLazySingleton<ChatRepository>(
    () => ChatRepositoryImpl(apiService: sl<ChatApiService>()),
  );
  
  // BLoCs
  sl.registerFactory<ChatBloc>(
    () => ChatBloc(repository: sl<ChatRepository>()),
  );
}
