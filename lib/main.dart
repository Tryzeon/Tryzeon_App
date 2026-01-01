import 'package:cached_query_flutter/cached_query_flutter.dart';
import 'package:cached_storage/cached_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/auth/data/auth_service.dart';
import 'package:tryzeon/feature/auth/presentation/pages/login_page.dart';
import 'package:tryzeon/feature/personal/main/personal_entry.dart';
import 'package:tryzeon/feature/store/main/store_entry.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await dotenv.load();

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    authOptions: const FlutterAuthClientOptions(authFlowType: AuthFlowType.pkce),
  );

  final storage = await CachedStorage.ensureInitialized();
  CachedQuery.instance.configFlutter(
    storage: storage,
    config: const GlobalQueryConfig(
      staleDuration: Duration(days: 30),
      storageDuration: Duration(days: 60),
      storeQuery: true,
    ),
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
