import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:ai_chat_app/main.dart'; // Import MyApp to access apiBaseUrl

// Import the generated file
import 'injection.config.dart';

final getIt = GetIt.instance;

@InjectableInit(
  initializerName: r'$initGetIt', // default
  preferRelativeImports: true, // default
  asExtension: false, // default
)
Future<void> init() async {
  // Manual registration of ChatApiService is removed.
  // $initGetIt will now use the generated registrations.
  $initGetIt(getIt);
}

// Add a module to provide dependencies like baseUrl
@module
abstract class RegisterModule {
  @Named('baseUrl')
  @lazySingleton
  String get baseUrl => MyApp.apiBaseUrl;

  // If Dio needed to be configured and injected:
  // @lazySingleton
  // Dio get dio => Dio(); // Example: basic Dio instance
}
