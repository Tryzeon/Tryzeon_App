import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:tryzeon/feature/auth/data/auth_service.dart';
import 'package:tryzeon/feature/auth/presentation/pages/login_page.dart';
import 'package:tryzeon/feature/store/main/store_entry.dart';
import 'package:tryzeon/shared/dialogs/confirmation_dialog.dart';
import 'profile_setting_page.dart';

class PersonalSettingsPage extends HookWidget {
  const PersonalSettingsPage({super.key});

  @override
  Widget build(final BuildContext context) {
    final hasChanges = useState(false);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    Future<void> handleSignOut() async {
      final confirmed = await ConfirmationDialog.show(
        context: context,
        title: '登出',
        content: '你確定要登出嗎？',
        confirmText: '登出',
      );

      if (confirmed == true) {
        await AuthService.signOut();
        if (context.mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (final context) => const LoginPage()),
            (final route) => false,
          );
        }
      }
    }

    Future<void> switchToStore() async {
      final confirmed = await ConfirmationDialog.show(
        context: context,
        title: '切換帳號',
        content: '你確定要切換到店家版帳號嗎？',
      );
      if (confirmed != true) return;

      await AuthService.setLastLoginType(UserType.store);

      if (!context.mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (final context) => const StoreEntry()),
        (final route) => false,
      );
    }

    Future<void> navigateToProfile() async {
      final updated = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (final context) => const PersonalProfileSettingsPage(),
        ),
      );
      if (updated == true) {
        hasChanges.value = true;
      }
    }

    Widget buildAppBar() {
      return Container(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_rounded,
                  color: colorScheme.primary,
                  size: 20,
                ),
                onPressed: () => Navigator.pop(context, hasChanges.value),
                padding: EdgeInsets.zero,
              ),
            ),
            const SizedBox(width: 12),
            Text('設定', style: textTheme.displaySmall?.copyWith(letterSpacing: 0.5)),
          ],
        ),
      );
    }

    Widget buildMenuCard({
      required final IconData icon,
      required final String title,
      required final String subtitle,
      required final VoidCallback onTap,
      final Gradient? gradient,
    }) {
      return Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient:
                          gradient ??
                          LinearGradient(
                            colors: [
                              colorScheme.primary.withValues(alpha: 0.1),
                              colorScheme.secondary.withValues(alpha: 0.1),
                            ],
                          ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(icon, color: colorScheme.primary, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: textTheme.titleSmall),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: textTheme.bodySmall?.copyWith(
                            fontSize: 13,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: colorScheme.outline,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    Widget buildLogoutButton() {
      return Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          border: Border.all(color: colorScheme.error, width: 2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: handleSignOut,
            borderRadius: BorderRadius.circular(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.logout_rounded, color: colorScheme.error, size: 24),
                const SizedBox(width: 8),
                Text(
                  '登出',
                  style: textTheme.titleSmall?.copyWith(color: colorScheme.error),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.surface,
              Color.alphaBlend(
                colorScheme.primary.withValues(alpha: 0.05),
                colorScheme.surface,
              ),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 頂部標題區
              buildAppBar(),

              // 功能列表
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),

                      // 選單項目 1
                      buildMenuCard(
                        icon: Icons.person_outline_rounded,
                        title: '基本資料',
                        subtitle: '編輯您的個人資訊',
                        onTap: navigateToProfile,
                      ),
                      const SizedBox(height: 12),

                      // 選單項目 2
                      buildMenuCard(
                        icon: Icons.store_outlined,
                        title: '切換到店家帳號',
                        subtitle: '管理您的商店',
                        onTap: switchToStore,
                      ),

                      const Spacer(),

                      // 登出按鈕
                      buildLogoutButton(),

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
