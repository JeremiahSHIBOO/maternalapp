import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/start_screen.dart';

void main() async {
  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://YOUR_PROJECT_REF.supabase.co',
    anonKey: 'YOUR_ANON_PUBLISHABLE_KEY',
  );

  runApp(const MaternalHealthApp());
}

class MaternalHealthApp extends StatelessWidget {
  const MaternalHealthApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MatruCare',
      theme: ThemeData(
        primarySwatch: Color(0xFF880E4F),
        scaffoldBackgroundColor: const Color(0xFFFDF9),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Color(0xFF880E4F)),
          bodyMedium: TextStyle(color: Color(0xFF880E4F)),
        ),
      ),
      darkTheme: ThemeData(
        primarySwatch: Color(0xFF880E4F),
        scaffoldBackgroundColor: const Color(0xFF1A0F2F),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Color(0xFFFCE4EC)),
          bodyMedium: TextStyle(color: Color(0xFFFCE4EC)),
        ),
      ),
      themeMode: ThemeMode.light,
      onGenerateRoute: AppRoutes.onGenerateRoute,
      initialRoute: AppRoutes.start,
    );
  }
}