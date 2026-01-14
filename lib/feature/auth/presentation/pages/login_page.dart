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

    // Custom Design Tokens
    const primaryColor = Color(0xFF6366F1); // Indigo
    const secondaryColor = Color(0xFFEC4899); // Pink

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
                    context: context,
                    icon: Icons.person_rounded,
                    title: 'User Login',
                    subtitle: 'Virtual Try-On',
                    accentColor: primaryColor,
                    onTap: navigateToPersonalLogin,
                  ),

                  const SizedBox(height: 24),

                  _buildLoginOptionCard(
                    context: context,
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
    const brandColor = Color(0xFF6366F1); // Indigo
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
                color: brandColor.withValues(alpha: 0.25),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: const Icon(Icons.checkroom_rounded, size: 56, color: brandColor),
        ),
        const SizedBox(height: 32),

        // Title
        Text(
          'Tryzeon',
          style: Theme.of(context).textTheme.displayLarge?.copyWith(
            color: titleColor,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),

        Text(
          'Choose your identity',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: subtitleColor,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildLoginOptionCard({
    required final BuildContext context,
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
            color: cardBackgroundColor.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(alpha: 0.1),
                blurRadius: 25,
                offset: const Offset(0, 10),
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
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: titleColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: subtitleColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // Arrow
              Container(
                padding: const EdgeInsets.all(8),
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
