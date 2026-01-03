import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/feature/auth/domain/entities/user_type.dart';
import 'package:tryzeon/feature/auth/presentation/pages/login_page.dart';
import 'package:tryzeon/feature/auth/providers/providers.dart';
import 'package:tryzeon/feature/store/main/store_entry.dart';
import 'package:tryzeon/shared/dialogs/confirmation_dialog.dart';
import 'package:tryzeon/shared/pages/base_settings_page.dart';
import 'profile_setting_page.dart';

class PersonalSettingsPage extends HookConsumerWidget {
  const PersonalSettingsPage({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    Future<void> handleSignOut() async {
      final confirmed = await ConfirmationDialog.show(
        context: context,
        title: '登出',
        content: '你確定要登出嗎？',
        confirmText: '登出',
      );
      if (confirmed != true) return;

      final signOutUseCase = await ref.read(signOutUseCaseProvider.future);
      await signOutUseCase();
      if (!context.mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (final context) => const LoginPage()),
        (final route) => false,
      );
    }

    Future<void> switchToStore() async {
      final confirmed = await ConfirmationDialog.show(
        context: context,
        title: '切換帳號',
        content: '你確定要切換到店家版帳號嗎？',
      );
      if (confirmed != true) return;

      final setLoginTypeUseCase = await ref.read(setLastLoginTypeUseCaseProvider.future);
      await setLoginTypeUseCase(UserType.store);
      if (!context.mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (final context) => const StoreEntry()),
        (final route) => false,
      );
    }

    Future<void> navigateToProfile() async {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (final context) => const PersonalProfileSettingsPage(),
        ),
      );
    }

    return SettingsPageScaffold(
      onBack: () => Navigator.pop(context),
      onLogout: handleSignOut,
      menuItems: [
        SettingsMenuItem(
          icon: Icons.person_outline_rounded,
          title: '基本資料',
          subtitle: '編輯您的個人資訊',
          onTap: navigateToProfile,
          gradient: LinearGradient(
            colors: [
              colorScheme.primary.withValues(alpha: 0.1),
              colorScheme.secondary.withValues(alpha: 0.1),
            ],
          ),
        ),
        SettingsMenuItem(
          icon: Icons.store_outlined,
          title: '切換到店家帳號',
          subtitle: '管理您的商店',
          onTap: switchToStore,
          gradient: LinearGradient(
            colors: [
              colorScheme.primary.withValues(alpha: 0.1),
              colorScheme.secondary.withValues(alpha: 0.1),
            ],
          ),
        ),
      ],
    );
  }
}
