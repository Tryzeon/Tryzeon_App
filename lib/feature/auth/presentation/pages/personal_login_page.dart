import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:tryzeon/feature/auth/data/auth_service.dart';
import 'package:tryzeon/feature/auth/presentation/widgets/login_scaffold.dart';
import 'package:tryzeon/feature/personal/main/personal_entry.dart';
import 'package:tryzeon/shared/widgets/top_notification.dart';
import 'package:typed_result/typed_result.dart';

class PersonalLoginPage extends HookWidget {
  const PersonalLoginPage({super.key});

  @override
  Widget build(final BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final isLoading = useState(false);
    final appLifecycleState = useAppLifecycleState();

    useEffect(() {
      if (appLifecycleState == AppLifecycleState.resumed) {
        if (isLoading.value) {
          isLoading.value = false;
        }
      }
      return null;
    }, [appLifecycleState]);

    Future<void> handleSignIn(final String provider) async {
      isLoading.value = true;

      final result = await AuthService.signInWithProvider(
        provider: provider,
        userType: UserType.personal,
      );

      // Check if widget is still mounted (HookWidget handles this generally, but safety is good)
      if (!context.mounted) return;
      isLoading.value = false;

      if (result.isSuccess) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (final context) => const PersonalEntry()),
        );
      } else {
        TopNotification.show(
          context,
          message: result.getError()!,
          type: NotificationType.error,
        );
      }
    }

    Widget buildHeader(final BuildContext context) {
      return Column(
        children: [
          // Logo Icon
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: colorScheme.surface, width: 4),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.secondary.withValues(alpha: 0.2),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Icon(Icons.person_rounded, size: 48, color: colorScheme.secondary),
          ),
          const SizedBox(height: 32),

          // Title
          Text(
            'Welcome!',
            style: textTheme.displaySmall?.copyWith(
              color: colorScheme.secondary,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),

          Text(
            'Ready to try on some new looks?',
            style: textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              letterSpacing: 0.2,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    Widget buildLoginButton(final String provider, final VoidCallback onTap) {
      return Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: colorScheme.secondary.withValues(alpha: 0.1),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(32),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    'assets/images/logo/$provider.svg',
                    height: 24,
                    width: 24,
                  ),
                  const SizedBox(width: 12),
                  Text('Continue with $provider', style: textTheme.titleMedium),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return CustomizeScaffold(
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: screenHeight * 0.02),

                // Back Button
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    style: IconButton.styleFrom(
                      backgroundColor: colorScheme.surface,
                      padding: const EdgeInsets.all(12),
                      elevation: 2,
                      shadowColor: Colors.black12,
                    ),
                  ),
                ),

                SizedBox(height: screenHeight * 0.05),

                // Header
                buildHeader(context),

                const Spacer(),

                // Login Buttons
                buildLoginButton('Google', () => handleSignIn('Google')),
                const SizedBox(height: 16),
                buildLoginButton('Facebook', () => handleSignIn('Facebook')),
                const SizedBox(height: 16),
                buildLoginButton('Apple', () => handleSignIn('Apple')),

                SizedBox(height: screenHeight * 0.1),
              ],
            ),
          ),
          if (isLoading.value)
            Container(
              color: Colors.black.withValues(alpha: 0.5),
              child: Center(
                child: CircularProgressIndicator(color: colorScheme.onPrimary),
              ),
            ),
        ],
      ),
    );
  }
}
