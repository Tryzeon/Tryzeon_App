import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/feature/auth/data/auth_service.dart';
import 'package:tryzeon/feature/auth/presentation/pages/login_page.dart';
import 'package:tryzeon/feature/personal/main/personal_entry.dart';
import 'package:tryzeon/shared/dialogs/confirmation_dialog.dart';
import 'package:tryzeon/shared/pages/base_settings_page.dart';
import 'profile_setting_page.dart';

class StoreSettingsPage extends HookConsumerWidget {
  const StoreSettingsPage({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    Future<void> switchToPersonal() async {
      final confirmed = await ConfirmationDialog.show(
        context: context,
        title: '切換帳號',
        content: '你確定要切換到個人版帳號嗎？',
      );
      if (confirmed != true) return;

      await AuthService.setLastLoginType(UserType.personal);
      if (!context.mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (final context) => const PersonalEntry()),
        (final route) => false,
      );
    }

    Future<void> handleSignOut() async {
      final confirmed = await ConfirmationDialog.show(
        context: context,
        title: '登出',
        content: '你確定要登出嗎？',
        confirmText: '登出',
      );
      if (confirmed != true) return;

      await AuthService.signOut();
      if (!context.mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (final context) => const LoginPage()),
        (final route) => false,
      );
    }

    Future<void> navigateToProfile() async {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (final context) => const StoreProfileSettingsPage()),
      );
    }

    return SettingsPageScaffold(
      onBack: () => Navigator.pop(context),
      onLogout: handleSignOut,
      menuItems: [
        SettingsMenuItem(
          icon: Icons.person_outline_rounded,
          title: '店家設定',
          subtitle: '管理店家資訊、Logo',
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
            ],
          ),
          onTap: navigateToProfile,
        ),
        SettingsMenuItem(
          icon: Icons.swap_horiz_rounded,
          title: '切換到個人帳號',
          subtitle: '切換回個人版本',
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            ],
          ),
          onTap: switchToPersonal,
        ),
      ],
    );
  }
}
