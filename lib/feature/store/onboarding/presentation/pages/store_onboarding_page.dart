import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/config/app_constants.dart';
import 'package:tryzeon/core/presentation/widgets/app_confirm_dialog.dart';
import 'package:tryzeon/core/presentation/widgets/top_notification.dart';
import 'package:tryzeon/core/router/app_routes.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/auth/domain/entities/user_type.dart';
import 'package:tryzeon/feature/auth/providers/auth_providers.dart';
import 'package:tryzeon/feature/store/profile/providers/store_profile_providers.dart';
import 'package:url_launcher/url_launcher.dart';

class StoreOnboardingPage extends HookConsumerWidget {
  const StoreOnboardingPage({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    Future<void> openForm() async {
      final uri = Uri.parse(AppConstants.storeOnboardingFormUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (!context.mounted) return;
        TopNotification.show(context, message: '無法開啟表單連結');
      }
    }

    Future<void> switchToPersonalAccount() async {
      final result = await showAppOkCancelDialog(
        context: context,
        title: '切換帳號',
        message: '你確定要切換到個人版帳號嗎？',
        okLabel: '確定',
        cancelLabel: '取消',
      );
      if (result != OkCancelResult.ok) return;
      final setLoginTypeUseCase = ref.read(setLastLoginTypeUseCaseProvider);
      await setLoginTypeUseCase(UserType.personal);
      if (context.mounted) context.go(AppRoutes.personalHome);
    }

    Future<void> handleLogout() async {
      final result = await showAppOkCancelDialog(
        context: context,
        title: '登出',
        message: '你確定要登出嗎？',
        okLabel: '登出',
        cancelLabel: '取消',
        isDestructiveAction: true,
      );
      if (result != OkCancelResult.ok) return;
      final signOutUseCase = ref.read(signOutUseCaseProvider);
      await signOutUseCase();
    }

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.read(storeProfileProvider.notifier).refresh(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.smMd,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.swap_horiz_outlined),
                      tooltip: '切換回個人帳號',
                      onPressed: switchToPersonalAccount,
                    ),
                    IconButton(
                      icon: const Icon(Icons.logout_outlined),
                      tooltip: '登出',
                      onPressed: handleLogout,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Text(
                  '品牌專區 · TRYZEON',
                  style: textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.smMd),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: RichText(
                  text: TextSpan(
                    style: textTheme.displayMedium?.copyWith(
                      color: colorScheme.onSurface,
                      height: 1.1,
                    ),
                    children: [
                      const TextSpan(text: '成為\n'),
                      TextSpan(
                        text: '認證品牌。',
                        style: textTheme.displayMedium?.copyWith(
                          fontStyle: FontStyle.italic,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Text(
                  '完成審核後，你的商品就能在 Tryzeon 上架、虛擬試穿與導購。',
                  style: textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurface,
                    height: 1.7,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: openForm,
                    icon: const Icon(Icons.open_in_new_rounded, size: 18),
                    label: const Text('開啟申請表單'),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              const Divider(indent: AppSpacing.lg, endIndent: AppSpacing.lg),
              const SizedBox(height: AppSpacing.lg),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Text(
                  '申請前須知',
                  style: textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.smMd),
              const _OnboardingNote(
                number: '01',
                label: '相同信箱',
                body: '必須使用與此帳號相同的 Gmail 填寫表單，否則無法綁定。',
              ),
              const _OnboardingNote(
                number: '02',
                label: '審核時程',
                body: '送出後，請等候 7 – 14 個工作天進行審核。',
              ),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingNote extends StatelessWidget {
  const _OnboardingNote({required this.number, required this.label, required this.body});

  final String number;
  final String label;
  final String body;

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.smMd,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            child: Text(
              number,
              style: textTheme.labelMedium?.copyWith(color: colorScheme.onSurface),
            ),
          ),
          const SizedBox(width: AppSpacing.smMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(body, style: textTheme.bodyMedium?.copyWith(height: 1.6)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
