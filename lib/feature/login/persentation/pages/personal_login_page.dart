import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:tryzeon/shared/services/auth_service.dart';
import 'package:tryzeon/shared/component/top_notification.dart';
import 'package:tryzeon/feature/personal/personal_entry.dart';

class PersonalLoginPage extends StatefulWidget {
  const PersonalLoginPage({super.key});

  @override
  State<PersonalLoginPage> createState() => _PersonalLoginPageState();
}

class _PersonalLoginPageState extends State<PersonalLoginPage> {
  void _showError(String message) {
    if (!mounted) return;
    TopNotification.show(
      context,
      message: message,
      type: NotificationType.error,
    );
  }

  Future<void> _handleGoogleSignIn() async {
    final result = await AuthService.signInWithGoogle(
      userType: UserType.personal,
    );

    if (result.success && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const PersonalEntry()),
      );
    } else if (!result.success) {
      _showError(result.errorMessage ?? 'Google 登入失敗');
    }
  }

  Future<void> _handleFacebookSignIn() async {
    final result = await AuthService.signInWithFacebook(
      userType: UserType.personal,
    );

    if (result.success && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const PersonalEntry()),
      );
    } else if (!result.success) {
      _showError(result.errorMessage ?? 'Facebook 登入失敗');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.surface,
              Color.alphaBlend(
                Colors.white.withValues(alpha: 0.2),
                Theme.of(context).colorScheme.surface,
              ),
              Color.alphaBlend(
                Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
                Theme.of(context).colorScheme.surface,
              ),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: screenHeight * 0.05),

                // 返回按鈕
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_rounded),
                    style: IconButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
                      padding: const EdgeInsets.all(12),
                    ),
                  ),
                ),

                SizedBox(height: screenHeight * 0.05),

                // Logo與標題區域
                _buildHeader(context),

                const Spacer(),

                // Google 登入按鈕
                _buildGoogleButton(),

                const SizedBox(height: 16),

                // Facebook 登入按鈕
                _buildFacebookButton(),

                SizedBox(height: screenHeight * 0.1),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      children: [
        // Logo圖示
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.secondary,
                Theme.of(context).colorScheme.secondary.withValues(alpha: 0.7),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(
            Icons.person_outline_rounded,
            size: 48,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 32),

        // 標題
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [
              Theme.of(context).colorScheme.secondary,
              Theme.of(context).colorScheme.primary,
            ],
          ).createShader(bounds),
          child: Text(
            '歡迎回來!',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 16),

        Text(
          '開始體驗虛擬試穿服務',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                letterSpacing: 0.5,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildGoogleButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Colors.white.withValues(alpha: 0.95),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _handleGoogleSignIn,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
            child: Row(
              children: [
                const SizedBox(width: 60),
                SvgPicture.asset(
                  'assets/images/logo/google.svg',
                  height: 24,
                  width: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  '使用 Google 登入',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.black87,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFacebookButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Colors.white.withValues(alpha: 0.95),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _handleFacebookSignIn,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
            child: Row(
              children: [
                const SizedBox(width: 60),
                SvgPicture.asset(
                  'assets/images/logo/facebook.svg',
                  height: 24,
                  width: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  '使用 Facebook 登入',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.black87,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}