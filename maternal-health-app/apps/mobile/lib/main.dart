import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app_config.dart';
import 'routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (AppConfig.isConfigured) {
    await Supabase.initialize(url: AppConfig.supabaseUrl, publishableKey: AppConfig.supabaseAnonKey);
  }

  runApp(const MaternalHealthApp());
}

class MaternalHealthApp extends StatelessWidget {
  const MaternalHealthApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MatruCare',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF880E4F)),
        scaffoldBackgroundColor: const Color(0xFFFFF9FC),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Color(0xFF880E4F)),
          bodyMedium: TextStyle(color: Color(0xFF880E4F)),
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF880E4F), brightness: Brightness.dark),
        scaffoldBackgroundColor: const Color(0xFF1A0F2F),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Color(0xFFFCE4EC)),
          bodyMedium: TextStyle(color: Color(0xFFFCE4EC)),
        ),
      ),
      themeMode: ThemeMode.system,
      onGenerateRoute: AppRoutes.onGenerate,
      initialRoute: AppRoutes.start,
    );
  }
}
