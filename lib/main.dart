import 'package:flutter/material.dart';
import 'pages/welcome_page.dart';

void main() {
  runApp(const TodoApp());
}

class TodoApp extends StatelessWidget {
  const TodoApp({Key? key}) : super(key: key); // Tambahkan key

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SkyList App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFFB3E5FC),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFFB3E5FC),
          secondary: Color(0xFF81D4FA),
          surface: Color(0xFFE1F5FE), // Ganti background -> surface
        ),
        scaffoldBackgroundColor: const Color(0xFFE1F5FE),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFB3E5FC),
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.black87),
          titleTextStyle: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF81D4FA),
            foregroundColor: Colors.black87,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      home: const WelcomePage(), // disarankan gunakan const jika memungkinkan
    );
  }
}
