import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ai_chat_app/features/chat/presentation/chat_page.dart';
import 'package:ai_chat_app/features/login/presentation/login_page.dart';
import 'package:ai_chat_app/features/splash/presentation/splash_page.dart';
import 'package:ai_chat_app/injection.dart' as di;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.init();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // Example: Define your backend base URL here
  static const String apiBaseUrl = "http://localhost:8000"; // or your server's IP

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Chat App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: SplashPage(),
      routes: {
        '/login': (context) => LoginPage(),
        '/chat': (context) => ChatPage(),
      },
    );
  }
}