import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:simple_icons/simple_icons.dart';
import 'package:tryzeon/core/extensions/failure_extension.dart';
import 'package:tryzeon/core/presentation/widgets/app_action_sheet.dart';
import 'package:tryzeon/core/presentation/widgets/app_confirm_dialog.dart';
import 'package:tryzeon/core/presentation/widgets/loading_overlay.dart';
import 'package:tryzeon/core/presentation/widgets/nav_row.dart';
import 'package:tryzeon/core/presentation/widgets/top_notification.dart';
import 'package:tryzeon/core/presentation/widgets/version_info.dart';
import 'package:tryzeon/core/router/app_routes.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/store/profile/providers/store_profile_providers.dart';
import 'package:tryzeon/feature/store/settings/presentation/providers/store_settings_controller.dart';
import 'package:url_launcher/url_launcher.dart';

class StoreSettingsPage extends HookConsumerWidget {
  const StoreSettingsPage({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final controller = ref.watch(storeSettingsControllerProvider.notifier);
    final state = ref.watch(storeSettingsControllerProvider);
    final profile = ref.watch(storeProfileProvider).value;

    ref.listen(storeSettingsControllerProvider, (final previous, final next) {
      if (next is AsyncError) {
        TopNotification.show(context, message: next.error.displayMessage(context));
      }
    });

    Future<void> switchToPersonal() async {
      final result = await showAppOkCancelDialog(
        context: context,
        title: '切換帳號',
        message: '你確定要切換到個人版帳號嗎？',
        okLabel: '確定',
        cancelLabel: '取消',
      );
      if (result != OkCancelResult.ok) return;

      await controller.switchToPersonal();

      if (!context.mounted) return;

      context.go(AppRoutes.personalHome);
    }

    Future<void> handleSignOut() async {
      final result = await showAppOkCancelDialog(
        context: context,
        title: '登出',
        message: '你確定要登出嗎？',
        okLabel: '登出',
        cancelLabel: '取消',
        isDestructiveAction: true,
      );
      if (result != OkCancelResult.ok) return;

      await controller.signOut();
    }

    Future<void> openContactLink(final String url, final String label) async {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }

      if (!context.mounted) return;
      TopNotification.show(context, message: '目前無法開啟 $label 連結');
    }

    Future<void> handleContactUs() async {
      await showAppActionSheet(
        context,
        title: '聯絡我們',
        actions: [
          AppMenuAction(
            icon: SimpleIcons.line,
            title: 'LINE 官方帳號',
            onTap: () => openContactLink('https://lin.ee/rY3VZMB', 'LINE'),
          ),
          AppMenuAction(
            icon: SimpleIcons.instagram,
            title: 'Instagram',
            onTap: () =>
                openContactLink('https://www.instagram.com/tryzeon/', 'Instagram'),
          ),
        ],
      );
    }

    Future<void> handleDeleteAccount() async {
      final dialogResult = await showAppOkCancelDialog(
        context: context,
        title: '刪除帳號',
        message: '此操作將永久刪除您的帳號及所有相關資料，包括個人資料、衣櫃、店家資料、商品等，且無法復原。您確定要繼續嗎？',
        okLabel: '刪除帳號',
        cancelLabel: '取消',
        isDestructiveAction: true,
      );
      if (dialogResult != OkCancelResult.ok) return;

      await controller.deleteAccount();
    }

    return LoadingOverlay(
      isLoading: state.isLoading,
      child: Scaffold(
        appBar: AppBar(title: const Text('設定')),
        body: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionLabel('店家'),
                NavRow(
                  icon: Icons.storefront_outlined,
                  title: '店家資料',
                  trailingValue: profile?.name,
                  isFirst: true,
                  onTap: () => context.push(AppRoutes.dashboardSettingsProfile),
                ),
                const _SectionLabel('支援'),
                NavRow(
                  icon: Icons.swap_horiz_rounded,
                  title: '切換到個人帳號',
                  isFirst: true,
                  onTap: switchToPersonal,
                ),
                NavRow(
                  icon: Icons.chat_bubble_outline,
                  title: '聯絡我們',
                  onTap: handleContactUs,
                ),
                _SectionLabel('危險區域', color: colorScheme.error),
                NavRow(
                  icon: Icons.logout,
                  title: '登出',
                  isDestructive: true,
                  isFirst: true,
                  showChevron: false,
                  onTap: handleSignOut,
                ),
                NavRow(
                  icon: Icons.delete_outline,
                  title: '刪除帳號',
                  isDestructive: true,
                  showChevron: false,
                  onTap: handleDeleteAccount,
                ),
                const SizedBox(height: AppSpacing.xxl),
                VersionInfo(
                  versionProvider: (final ref) =>
                      ref.read(storeSettingsControllerProvider.notifier).getAppVersion(),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text, {this.color});

  final String text;
  final Color? color;

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);
    final resolved = color ?? theme.colorScheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: AppSpacing.sm),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(text, style: theme.textTheme.labelLarge?.copyWith(color: resolved)),
      ),
    );
  }
}
