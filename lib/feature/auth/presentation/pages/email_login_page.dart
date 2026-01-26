import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/config/app_constants.dart';
import 'package:tryzeon/core/presentation/widgets/top_notification.dart';
import 'package:tryzeon/feature/auth/domain/entities/user_type.dart';
import 'package:tryzeon/feature/auth/presentation/widgets/login_scaffold.dart';
import 'package:tryzeon/feature/auth/providers/auth_providers.dart';
import 'package:tryzeon/feature/personal/main/personal_entry.dart';
import 'package:tryzeon/feature/store/main/store_entry.dart';
import 'package:typed_result/typed_result.dart';

class EmailLoginPage extends HookConsumerWidget {
  const EmailLoginPage({super.key, required this.userType});

  final UserType userType;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final screenHeight = MediaQuery.of(context).size.height;

    // Custom Design Tokens - Clean Premium Light
    const primaryColor = Color(0xFF6366F1); // Indigo 500
    const titleColor = Color(0xFF1E293B); // Slate 800
    const subtitleColor = Color(0xFF64748B); // Slate 500

    final emailController = useTextEditingController();
    final tokenController = useTextEditingController();
    final isLoading = useState(false);
    final isOtpSent = useState(false);
    final resendCountdown = useState(0);

    // Countdown timer effect
    useEffect(() {
      Timer? timer;
      if (resendCountdown.value > 0) {
        timer = Timer.periodic(const Duration(seconds: 1), (final t) {
          if (resendCountdown.value > 0) {
            resendCountdown.value--;
          } else {
            t.cancel();
          }
        });
      }
      return () => timer?.cancel();
    }, [resendCountdown.value]);

    // Validation
    bool isValidEmail(final String email) {
      return RegExp(
        r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%\&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
      ).hasMatch(email);
    }

    Future<void> handleSendEmailOtp({final bool isResend = false}) async {
      final email = emailController.text.trim();
      if (email.isEmpty || !isValidEmail(email)) {
        TopNotification.show(
          context,
          message: '請輸入有效的電子郵件地址',
          type: NotificationType.error,
        );
        return;
      }

      // Close keyboard
      FocusScope.of(context).unfocus();

      isLoading.value = true;

      final useCase = await ref.read(sendEmailOtpUseCaseProvider.future);
      final result = await useCase(email: email, userType: userType);

      if (context.mounted) {
        isLoading.value = false;
        if (result.isSuccess) {
          isOtpSent.value = true;
          tokenController.clear();
          resendCountdown.value = AppConstants.otpResendCountdownSeconds;
          TopNotification.show(
            context,
            message: isResend ? '驗證碼已重新發送' : '驗證碼已發送，請檢查您的信箱',
            type: NotificationType.success,
          );
        } else {
          TopNotification.show(
            context,
            message: result.getError() ?? '發送失敗，請稍後再試',
            type: NotificationType.error,
          );
        }
      }
    }

    Future<void> handleVerifyEmailOtp() async {
      final email = emailController.text.trim();
      final token = tokenController.text.trim();

      if (token.isEmpty) {
        TopNotification.show(context, message: '請輸入驗證碼', type: NotificationType.error);
        return;
      }

      FocusScope.of(context).unfocus();
      isLoading.value = true;

      final useCase = await ref.read(verifyEmailOtpUseCaseProvider.future);
      final result = await useCase(email: email, token: token, userType: userType);

      if (context.mounted) {
        isLoading.value = false;

        if (result.isSuccess) {
          // Navigate to respective home page
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (final context) => userType == UserType.personal
                  ? const PersonalEntry()
                  : const StoreEntry(),
            ),
            (final route) => false,
          );
        } else {
          TopNotification.show(
            context,
            message: result.getError() ?? '驗證失敗，請檢查驗證碼是否正確',
            type: NotificationType.error,
          );
        }
      }
    }

    Widget buildHeader() {
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
            child: Icon(
              isOtpSent.value ? Icons.mark_email_read_rounded : Icons.email_rounded,
              size: 40,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 32),

          // Title
          Text(
            isOtpSent.value ? '輸入驗證碼' : '電子郵件登入',
            style: const TextStyle(
              color: titleColor,
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.0,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),

          Text(
            isOtpSent.value ? '我們已發送驗證碼至 ${emailController.text}' : '我們將發送驗證碼至您的電子信箱',
            style: const TextStyle(
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

    Widget buildInput({
      required final TextEditingController controller,
      required final String hint,
      required final IconData icon,
      final bool isNumber = false,
      final TextInputAction? textInputAction,
      final void Function(String)? onSubmitted,
    }) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextFormField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.emailAddress,
          textInputAction: textInputAction,
          onFieldSubmitted: onSubmitted,
          style: const TextStyle(
            color: titleColor,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: subtitleColor.withValues(alpha: 0.7)),
            prefixIcon: Icon(icon, color: primaryColor.withValues(alpha: 0.7)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.transparent,
            contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
          ),
        ),
      );
    }

    Widget buildActionButton({
      required final String text,
      required final VoidCallback onTap,
    }) {
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFF4F46E5)], // Indigo 500 to 600
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      );
    }

    return CustomizeScaffold(
      body: Stack(
        children: [
          // Main Scrollable Content with Tap-to-Dismiss
          GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: LayoutBuilder(
              builder: (final context, final constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: IntrinsicHeight(
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
                                onPressed: () {
                                  if (isOtpSent.value) {
                                    isOtpSent.value = false;
                                  } else {
                                    Navigator.pop(context);
                                  }
                                },
                                icon: const Icon(
                                  Icons.arrow_back_ios_new_rounded,
                                  size: 20,
                                ),
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: titleColor,
                                  padding: const EdgeInsets.all(12),
                                  elevation: 0,
                                  side: const BorderSide(color: Colors.white, width: 2),
                                ),
                              ),
                            ),
                          ),

                          SizedBox(height: screenHeight * 0.04),

                          buildHeader(),

                          const SizedBox(height: 48),

                          // Form
                          AnimatedSwitcher(
                            duration: AppConstants.defaultAnimationDuration,
                            child: isOtpSent.value
                                ? Column(
                                    key: const ValueKey('otp_form'),
                                    children: [
                                      buildInput(
                                        controller: tokenController,
                                        hint: '輸入 6 位數驗證碼',
                                        icon: Icons.lock_outline_rounded,
                                        isNumber: true,
                                        textInputAction: TextInputAction.done,
                                        onSubmitted: (final _) => handleVerifyEmailOtp(),
                                      ),
                                      const SizedBox(height: 24),
                                      buildActionButton(
                                        text: '驗證並登入',
                                        onTap: handleVerifyEmailOtp,
                                      ),
                                      const SizedBox(height: 16),
                                      // Resend button
                                      Center(
                                        child: TextButton(
                                          onPressed: resendCountdown.value > 0
                                              ? null
                                              : () => handleSendEmailOtp(isResend: true),
                                          child: Text(
                                            resendCountdown.value > 0
                                                ? '重新發送 (${resendCountdown.value}s)'
                                                : '重新發送驗證碼',
                                            style: TextStyle(
                                              color: resendCountdown.value > 0
                                                  ? subtitleColor.withValues(alpha: 0.5)
                                                  : primaryColor,
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                : Column(
                                    key: const ValueKey('email_form'),
                                    children: [
                                      buildInput(
                                        controller: emailController,
                                        hint: 'name@example.com',
                                        icon: Icons.alternate_email_rounded,
                                        textInputAction: TextInputAction.next,
                                        onSubmitted: (final _) => handleSendEmailOtp(),
                                      ),
                                      const SizedBox(height: 24),
                                      buildActionButton(
                                        text: '發送驗證碼',
                                        onTap: handleSendEmailOtp,
                                      ),
                                    ],
                                  ),
                          ),
                          // Spacer to ensure content has bottom padding when scrolling
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Loading Overlay
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
