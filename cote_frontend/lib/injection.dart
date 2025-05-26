import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:ai_chat_app/main.dart';

// Import our manual implementation
import 'injection_manual.dart';

final getIt = GetIt.instance;

@module
abstract class RegisterModule {
  @Named('baseUrl')
  @lazySingleton
  String get baseUrl => MyApp.apiBaseUrl;
}

Future<void> init() async {
  try {
    // Use our manual implementation instead of the generated one
    $initGetIt(getIt);
  } catch (e) {
    print('Error initializing dependencies: $e');
    rethrow;
  }
}
