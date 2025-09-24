import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/pages/login/login_page.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: 'https://pxcjggvvcipyzftsdexc.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InB4Y2pnZ3Z2Y2lweXpmdHNkZXhjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg3MTM4ODUsImV4cCI6MjA3NDI4OTg4NX0.UC6pqxavhjiDwDuoYson3ikojOnWXeSreW8Sv8uFjMg',
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
      routes: {
        // Add your routes here if needed
      },
    );
  }
}

