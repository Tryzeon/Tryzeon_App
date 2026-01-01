import 'package:flutter/material.dart';
import 'package:tryzeon/feature/auth/presentation/widgets/customize_scaffold.dart';
// Import AppTheme to access static colors if needed, or just use Theme.of(context)

import 'personal_login_page.dart';
import 'store_login_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _navigateToPersonalLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (final context) => const PersonalLoginPage()),
    );
  }

  void _navigateToStoreLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (final context) => const StoreLoginPage()),
    );
  }

  @override
  Widget build(final BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final colorScheme = Theme.of(context).colorScheme;

    return CustomizeScaffold(
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: screenHeight * 0.08),

                // Logo area
                _buildHeader(context),

                SizedBox(height: screenHeight * 0.06),

                // Buttons
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildLoginOptionCard(
                        context: context,
                        icon: Icons.person_rounded, // Rounded icon
                        title: 'User Login',
                        subtitle: 'Virtual Try-On',
                        color: colorScheme.secondary,
                        onTap: _navigateToPersonalLogin,
                        delay: 100,
                      ),

                      const SizedBox(height: 24),

                      _buildLoginOptionCard(
                        context: context,
                        icon: Icons.store_rounded, // Rounded icon
                        title: 'Store Login',
                        subtitle: 'Manage Products',
                        color: colorScheme.primary,
                        onTap: _navigateToStoreLogin,
                        delay: 200,
                      ),
                    ],
                  ),
                ),

                SizedBox(height: screenHeight * 0.05),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        // Logo Container
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
            border: Border.all(color: colorScheme.surface, width: 2),
          ),
          child: Icon(Icons.checkroom_rounded, size: 56, color: colorScheme.primary),
        ),
        const SizedBox(height: 24),

        // Title
        Text(
          'Tryzeon',
          style: textTheme.displayLarge?.copyWith(
            color: colorScheme.primary,
            letterSpacing: -1.0, // Tighter spacing for display font
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),

        Text(
          'Choose your identity',
          style: textTheme.titleMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
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
    required final Color color,
    required final VoidCallback onTap,
    required final int delay,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + delay),
      curve: Curves.easeOutBack,
      builder: (final context, final value, final child) {
        return Transform.scale(
          scale: value,
          child: Opacity(opacity: value.clamp(0.0, 1.0), child: child),
        );
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(32),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colorScheme.surface.withValues(alpha: 0.7), // Glassy
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: colorScheme.surface, width: 2),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                // Icon Circle
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 32, color: color),
                ),
                const SizedBox(width: 20),

                // Text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: textTheme.headlineSmall),
                      const SizedBox(height: 4),
                      Text(subtitle, style: textTheme.bodyMedium),
                    ],
                  ),
                ),

                // Arrow
                Icon(Icons.arrow_forward_rounded, color: color, size: 28),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
