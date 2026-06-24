import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/extensions/failure_extension.dart';
import 'package:tryzeon/core/presentation/widgets/top_notification.dart';
import 'package:tryzeon/core/presentation/widgets/version_info.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/auth/domain/entities/user_type.dart';
import 'package:tryzeon/feature/auth/presentation/sheets/email_otp_bottom_sheet.dart';
import 'package:tryzeon/feature/auth/presentation/widgets/identity_segmented_control.dart';
import 'package:tryzeon/feature/auth/providers/auth_providers.dart';
import 'package:typed_result/typed_result.dart';

class LoginPage extends HookConsumerWidget {
  const LoginPage({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final userType = useState(UserType.personal);
    final isLoading = useState(false);

    Future<void> handleSocialLogin(final String provider) async {
      isLoading.value = true;
      final signInUseCase = ref.read(signInWithProviderUseCaseProvider);
      final result = await signInUseCase(provider: provider, userType: userType.value);

      if (!context.mounted) return;
      isLoading.value = false;

      if (!result.isSuccess) {
        final failure = result.getError()!;
        if (failure is UserCanceledFailure) return;
        TopNotification.show(context, message: failure.displayMessage(context));
      }
    }

    final softOutlineStyle = OutlinedButton.styleFrom(
      side: BorderSide(color: colorScheme.outline, width: AppStroke.thin),
    );

    Widget buildSocialButton(final String provider, final VoidCallback onTap) {
      return OutlinedButton(
        onPressed: isLoading.value ? null : onTap,
        style: softOutlineStyle,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset('assets/images/logo/$provider.svg', height: 20, width: 20),
            const SizedBox(width: AppSpacing.smMd),
            Text('使用 $provider 繼續'),
          ],
        ),
      );
    }

    Widget buildEmailButton() {
      return OutlinedButton(
        onPressed: isLoading.value
            ? null
            : () => EmailOtpBottomSheet.show(context, userType.value),
        style: softOutlineStyle,
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.email_outlined, size: 20),
            SizedBox(width: AppSpacing.smMd),
            Text('使用 Email 繼續'),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppSpacing.xxl),
                  Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.checkroom_rounded,
                          size: 48,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'Tryzeon',
                          style: Theme.of(context).textTheme.displayMedium?.copyWith(
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  Center(
                    child: IdentitySegmentedControl(
                      selectedType: userType.value,
                      onChanged: (final type) => userType.value = type,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Center(
                    child: Text(
                      userType.value == UserType.personal ? '開啟您的虛擬試衣間' : '開始您的商店管理之旅',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const Spacer(),
                  buildSocialButton('Apple', () => handleSocialLogin('Apple')),
                  const SizedBox(height: AppSpacing.md),
                  buildSocialButton('Google', () => handleSocialLogin('Google')),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      Expanded(
                        child: Divider(
                          color: colorScheme.outline,
                          thickness: AppStroke.thin,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                        child: Text(
                          '或',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          color: colorScheme.outline,
                          thickness: AppStroke.thin,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  buildEmailButton(),
                  const SizedBox(height: AppSpacing.lg),
                  VersionInfo(
                    versionProvider: (final _) async {
                      final packageInfo = await PackageInfo.fromPlatform();
                      return '${packageInfo.version} (${packageInfo.buildNumber})';
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
          ),
          if (isLoading.value)
            Container(
              color: colorScheme.surface.withValues(alpha: 0.8),
              child: Center(
                child: CircularProgressIndicator(color: colorScheme.onSurface),
              ),
            ),
        ],
      ),
    );
  }
}
