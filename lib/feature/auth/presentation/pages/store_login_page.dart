import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/presentation/widgets/top_notification.dart';
import 'package:tryzeon/feature/auth/domain/entities/user_type.dart';
import 'package:tryzeon/feature/auth/presentation/pages/email_login_page.dart';
import 'package:tryzeon/feature/auth/presentation/widgets/login_scaffold.dart';
import 'package:tryzeon/feature/auth/providers/auth_providers.dart';
import 'package:tryzeon/feature/store/main/store_entry.dart';
import 'package:typed_result/typed_result.dart';

class StoreLoginPage extends HookConsumerWidget {
  const StoreLoginPage({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final screenHeight = MediaQuery.of(context).size.height;

    // Custom Design Tokens - Clean Premium Light (Store Variant)
    const primaryColor = Color(0xFFE11D48); // Rose 600
    const titleColor = Color(0xFF1E293B); // Slate 800
    const subtitleColor = Color(0xFF64748B); // Slate 500

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

      final signInUseCase = await ref.read(signInWithProviderUseCaseProvider.future);
      final result = await signInUseCase(provider: provider, userType: UserType.store);

      // Check if widget is still mounted
      if (!context.mounted) return;
      isLoading.value = false;

      if (result.isSuccess) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (final context) => const StoreEntry()),
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withValues(alpha: 0.2),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.store_rounded, size: 40, color: primaryColor),
          ),
          const SizedBox(height: 32),

          // Title
          const Text(
            '歡迎 !',
            style: TextStyle(
              color: titleColor,
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.0,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),

          const Text(
            '開始您的商店管理之旅',
            style: TextStyle(
              color: subtitleColor,
              fontSize: 16,
              fontWeight: FontWeight.w500,
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
          color: Colors.white.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withValues(alpha: 0.05),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    'assets/images/logo/$provider.svg',
                    height: 24,
                    width: 24,
                  ),
                  const SizedBox(width: 14),
                  Text(
                    '使用 $provider 繼續',
                    style: const TextStyle(
                      color: Color(0xFF334155), // Slate 700
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
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
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: titleColor,
                        padding: const EdgeInsets.all(12),
                        elevation: 0,
                        side: const BorderSide(color: Colors.white, width: 2),
                        shadowColor: Colors.transparent,
                      ).copyWith(backgroundColor: WidgetStateProperty.all(Colors.white)),
                    ),
                  ),
                ),

                SizedBox(height: screenHeight * 0.04),

                // Header
                buildHeader(context),

                const Spacer(),

                // Login Buttons
                buildLoginButton('Google', () => handleSignIn('Google')),
                const SizedBox(height: 16),
                buildLoginButton('Facebook', () => handleSignIn('Facebook')),
                const SizedBox(height: 16),
                buildLoginButton('Apple', () => handleSignIn('Apple')),

                const SizedBox(height: 24),

                // Divider
                Row(
                  children: [
                    Expanded(child: Divider(color: subtitleColor.withValues(alpha: 0.3))),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        '或',
                        style: TextStyle(
                          color: subtitleColor.withValues(alpha: 0.7),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: subtitleColor.withValues(alpha: 0.3))),
                  ],
                ),

                const SizedBox(height: 24),

                // Email Login Button
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: primaryColor.withValues(alpha: 0.3),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withValues(alpha: 0.05),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (final context) =>
                                const EmailLoginPage(userType: UserType.store),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.email_outlined, size: 24, color: primaryColor),
                            SizedBox(width: 14),
                            Text(
                              '使用 Email 繼續',
                              style: TextStyle(
                                color: Color(0xFF334155),
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: screenHeight * 0.1),
              ],
            ),
          ),
          if (isLoading.value)
            Container(
              color: Colors.black.withValues(alpha: 0.2),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const CircularProgressIndicator(color: primaryColor),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
