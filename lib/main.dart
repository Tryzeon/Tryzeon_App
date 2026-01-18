import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/auth/domain/entities/user_type.dart';
import 'package:tryzeon/feature/auth/presentation/pages/login_page.dart';
import 'package:tryzeon/feature/auth/providers/providers.dart';
import 'package:tryzeon/feature/personal/main/personal_entry.dart';
import 'package:tryzeon/feature/store/main/store_entry.dart';
import 'package:typed_result/typed_result.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load();

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    authOptions: const FlutterAuthClientOptions(authFlowType: AuthFlowType.pkce),
  );

  runApp(const ProviderScope(child: Tryzeon()));
}

class Tryzeon extends HookConsumerWidget {
  const Tryzeon({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final isLoading = useState(true);
    final userType = useState<UserType?>(null);

    useEffect(() {
      Future<void> checkAuthStatus() async {
        final getLoginTypeUseCase = await ref.read(
          getLastLoginTypeUseCaseProvider.future,
        );
        final result = await getLoginTypeUseCase();
        switch (result) {
          case Ok(:final value):
            userType.value = value;
          case Err():
            userType.value = null;
        }
        isLoading.value = false;
      }

      checkAuthStatus();
      return null;
    }, []);

    return MaterialApp(
      title: 'TryZeon',
      theme: AppTheme.lightTheme,
      home: isLoading.value
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : userType.value == null
          ? const LoginPage()
          : userType.value == UserType.store
          ? const StoreEntry()
          : const PersonalEntry(),
    );
  }
}
