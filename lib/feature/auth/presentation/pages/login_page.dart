import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/feature/auth/presentation/widgets/login_scaffold.dart';
// Import AppTheme to access static colors if needed, or just use Theme.of(context)

import 'personal_login_page.dart';
import 'store_login_page.dart';

class LoginPage extends HookConsumerWidget {
  const LoginPage({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final screenHeight = MediaQuery.of(context).size.height;

    // Custom Design Tokens - Clean Premium Light
    const primaryColor = Color(0xFF6366F1); // Indigo 500
    const secondaryColor = Color(0xFFE11D48); // Rose 600 (Store accent)

    void navigateToPersonalLogin() {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (final context) => const PersonalLoginPage()),
      );
    }

    void navigateToStoreLogin() {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (final context) => const StoreLoginPage()),
      );
    }

    return CustomizeScaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: screenHeight * 0.08),

            // Logo area - Center aligned
            Center(child: _buildHeader(context)),

            SizedBox(height: screenHeight * 0.06),

            // Buttons
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLoginOptionCard(
                    icon: Icons.person_rounded,
                    title: 'User Login',
                    subtitle: 'Virtual Try-On',
                    accentColor: primaryColor,
                    onTap: navigateToPersonalLogin,
                  ),

                  const SizedBox(height: 24),

                  _buildLoginOptionCard(
                    icon: Icons.store_rounded,
                    title: 'Store Login',
                    subtitle: 'Manage Products',
                    accentColor: secondaryColor,
                    onTap: navigateToStoreLogin,
                  ),
                ],
              ),
            ),

            SizedBox(height: screenHeight * 0.05),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(final BuildContext context) {
    // Custom Tokens
    const brandColor = Color(0xFF6366F1); // Indigo 500
    const titleColor = Color(0xFF1E293B); // Slate 800
    const subtitleColor = Color(0xFF64748B); // Slate 500

    return Column(
      children: [
        // Logo Container
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: brandColor.withValues(alpha: 0.20),
                blurRadius: 32,
                offset: const Offset(0, 16),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(Icons.checkroom_rounded, size: 56, color: brandColor),
        ),
        const SizedBox(height: 32),

        // Title
        const Text(
          'Tryzeon',
          style: TextStyle(
            fontFamily:
                'Outfit', // Assuming Outfit or use default SANs with refined weight
            color: titleColor,
            fontSize: 40,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.5,
            height: 1.1,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),

        const Text(
          'Choose your identity',
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

  Widget _buildLoginOptionCard({
    required final IconData icon,
    required final String title,
    required final String subtitle,
    required final Color accentColor,
    required final VoidCallback onTap,
  }) {
    // Glassmorphism Card Style
    const cardBackgroundColor = Colors.white;
    const titleColor = Color(0xFF1E293B); // Slate 800
    const subtitleColor = Color(0xFF64748B); // Slate 500

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: cardBackgroundColor.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(alpha: 0.08),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Icon Circle
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(icon, size: 30, color: accentColor),
              ),
              const SizedBox(width: 20),

              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: titleColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: subtitleColor,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              // Arrow
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(Icons.arrow_forward_rounded, color: accentColor, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
