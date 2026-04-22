import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:telur_mobile/users/home.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Telur Mobile',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3F6B2A),
          primary: const Color(0xFF3F6B2A),
          secondary: const Color(0xFFE1A53B),
          surface: const Color(0xFFF8F5EC),
        ),
        scaffoldBackgroundColor: const Color(0xFFF8F5EC),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF2F4A2B),
        ),
        cardColor: Colors.white,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3F6B2A),
            foregroundColor: Colors.white,
          ),
        ),
      ),
      home: const HomePage(),
    );
  }
}
