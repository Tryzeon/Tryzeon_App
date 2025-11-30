import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/login/presentation/pages/login_page.dart';
import 'package:tryzeon/feature/personal/personal_entry.dart';
import 'package:tryzeon/feature/store/store_entry.dart';
import 'package:tryzeon/shared/services/auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://vshrdjgrweuuxtdqsevk.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZzaHJkamdyd2V1dXh0ZHFzZXZrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg4MTE0NzUsImV4cCI6MjA3NDM4NzQ3NX0.k-l5AN8VjVapOalYtMxXETf-Ijxq6X5qEqmajxNMLvM',
    authOptions: const FlutterAuthClientOptions(authFlowType: AuthFlowType.pkce),
  );

  runApp(const Tryzeon());
}

class Tryzeon extends StatefulWidget {
  const Tryzeon({super.key});

  @override
  State<Tryzeon> createState() => _TryzeonState();
}

class _TryzeonState extends State<Tryzeon> {
  bool _isLoading = true;
  UserType? _userType;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    final session = Supabase.instance.client.auth.currentSession;
    final user = session?.user;

    UserType? userType;
    if (user != null) {
      userType = await AuthService.getLastLoginType();
    }

    setState(() {
      _userType = userType;
      _isLoading = false;
    });
  }

  @override
  Widget build(final BuildContext context) {
    return MaterialApp(
      title: 'TryZeon',
      theme: AppTheme.lightTheme,
      home: _isLoading
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : _userType == null
          ? const LoginPage()
          : _userType == UserType.store
          ? const StoreEntry()
          : const PersonalEntry(),
    );
  }
}
