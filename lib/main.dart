import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/feature/login/persentation/pages/login_page.dart';
import 'package:tryzeon/feature/home/persentation/pages/home_navigator.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: 'https://vshrdjgrweuuxtdqsevk.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZzaHJkamdyd2V1dXh0ZHFzZXZrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg4MTE0NzUsImV4cCI6MjA3NDM4NzQ3NX0.k-l5AN8VjVapOalYtMxXETf-Ijxq6X5qEqmajxNMLvM',
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );
  
  runApp(const Tryzeon());
}

class Tryzeon extends StatelessWidget {
  const Tryzeon({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TryZeon',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.brown,
        ).copyWith(
          onSurface: Colors.brown[900],
        ),
        scaffoldBackgroundColor: const Color(0xFFFAF4EC),
        useMaterial3: true,
        textTheme: ThemeData.light().textTheme.apply(
          bodyColor: Colors.brown[700],
          displayColor: Colors.brown[700],
        ),
      ),
      home: const LoginPage(),
      // home: const HomeNavigator(),
      routes: {
        // Add your routes here if needed
      },
    );
  }
}

