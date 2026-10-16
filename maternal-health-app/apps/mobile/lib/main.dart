import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'app_config.dart';
import 'routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  if (AppConfig.isConfigured) {
    await Supabase.initialize(url: AppConfig.supabaseUrl, publishableKey: AppConfig.supabaseAnonKey);
  }

  runApp(const MaternalHealthApp());
}

class MaternalHealthApp extends StatelessWidget {
  const MaternalHealthApp({super.key});

  static const _ink = Color(0xFF28212A);
  static const _muted = Color(0xFF766E76);
  static const _plum = Color(0xFF70445E);
  static const _canvas = Color(0xFFFAF8F6);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MatruCare',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _plum,
          primary: _plum,
          secondary: const Color(0xFF789080),
          surface: Colors.white,
        ),
        scaffoldBackgroundColor: _canvas,
        appBarTheme: const AppBarTheme(
          backgroundColor: _canvas,
          foregroundColor: _ink,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(color: _ink, fontSize: 18, fontWeight: FontWeight.w600),
        ),
        textTheme: const TextTheme(
          headlineMedium: TextStyle(color: _ink, fontSize: 30, fontWeight: FontWeight.w600, height: 1.15, letterSpacing: -0.6),
          headlineSmall: TextStyle(color: _ink, fontSize: 24, fontWeight: FontWeight.w600, height: 1.2, letterSpacing: -0.3),
          titleLarge: TextStyle(color: _ink, fontSize: 18, fontWeight: FontWeight.w600),
          titleMedium: TextStyle(color: _ink, fontSize: 15, fontWeight: FontWeight.w600),
          bodyLarge: TextStyle(color: _ink, fontSize: 15, height: 1.5),
          bodyMedium: TextStyle(color: _muted, fontSize: 14, height: 1.45),
          bodySmall: TextStyle(color: _muted, fontSize: 12, height: 1.4),
          labelSmall: TextStyle(color: _muted, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.3),
          labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFFECE7E8)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE7E0E3))),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE7E0E3))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _plum, width: 1.5)),
          labelStyle: const TextStyle(color: _muted),
          hintStyle: const TextStyle(color: Color(0xFFA49BA1)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: _plum,
            foregroundColor: Colors.white,
            minimumSize: const Size(0, 52),
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            elevation: 0,
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: _plum, textStyle: const TextStyle(fontWeight: FontWeight.w600)),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: _plum,
            minimumSize: const Size(0, 48),
            side: const BorderSide(color: Color(0xFFE7E0E3)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      onGenerateRoute: AppRoutes.onGenerate,
      initialRoute: AppRoutes.start,
    );
  }
}
