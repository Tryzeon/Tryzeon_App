import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:tryzeon/feature/login/presentation/widgets/customize_scaffold.dart';
import 'package:tryzeon/feature/personal/personal_entry.dart';
import 'package:tryzeon/shared/services/auth_service.dart';
import 'package:tryzeon/shared/widgets/top_notification.dart';

class PersonalLoginPage extends StatefulWidget {
  const PersonalLoginPage({super.key});

  @override
  State<PersonalLoginPage> createState() => _PersonalLoginPageState();
}

class _PersonalLoginPageState extends State<PersonalLoginPage>
    with WidgetsBindingObserver {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(final AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_isLoading) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(final String message) {
    if (!mounted) return;
    TopNotification.show(
      context,
      message: message,
      type: NotificationType.error,
    );
  }

  Future<void> _handleSignIn(final String provider) async {
    setState(() => _isLoading = true);

    final result = await AuthService.signInWithProvider(
      provider: provider,
      userType: UserType.personal,
    );

    if (mounted) {
      setState(() => _isLoading = false);
    }

    if (result.isSuccess && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (final context) => const PersonalEntry()),
      );
    } else if (!result.isSuccess) {
      _showError(result.errorMessage!);
    }
  }

  @override
  Widget build(final BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final colorScheme = Theme.of(context).colorScheme;

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
                _buildHeader(context),

                const Spacer(),

                // Login Buttons
                _buildLoginButton('Google', () => _handleSignIn('Google')),
                const SizedBox(height: 16),
                _buildLoginButton('Facebook', () => _handleSignIn('Facebook')),
                const SizedBox(height: 16),
                _buildLoginButton('Apple', () => _handleSignIn('Apple')),

                SizedBox(height: screenHeight * 0.1),
              ],
            ),
          ),
          if (_isLoading)
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

  Widget _buildHeader(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
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
          child: Icon(
            Icons.person_rounded,
            size: 48,
            color: colorScheme.secondary,
          ),
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

  Widget _buildLoginButton(final String provider, final VoidCallback onTap) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

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
}
