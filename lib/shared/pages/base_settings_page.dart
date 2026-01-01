import 'package:flutter/material.dart';
import 'package:tryzeon/feature/auth/presentation/pages/login_page.dart';
import 'package:tryzeon/shared/dialogs/confirmation_dialog.dart';
import 'package:tryzeon/feature/auth/data/auth_service.dart';

/// 設定頁面的選單項目
class SettingsMenuItem {
  const SettingsMenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.gradient,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Gradient? gradient;
}

/// 基礎設定頁面
abstract class BaseSettingsPage extends StatefulWidget {
  const BaseSettingsPage({super.key});
}

abstract class BaseSettingsPageState<T extends BaseSettingsPage> extends State<T> {
  bool _hasChanges = false;

  // 子類需要實作這個方法
  List<SettingsMenuItem> buildMenuItems();

  void markAsChanged() {
    setState(() {
      _hasChanges = true;
    });
  }

  Future<void> handleSignOut(final BuildContext context) async {
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

  @override
  Widget build(final BuildContext context) {
    final menuItems = buildMenuItems();

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.surface,
              Color.alphaBlend(
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
                Theme.of(context).colorScheme.surface,
              ),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 頂部標題區
              _buildAppBar(context),

              // 功能列表
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),

                      // 動態生成選單項目
                      ...menuItems.asMap().entries.map((final entry) {
                        final index = entry.key;
                        final item = entry.value;
                        return Column(
                          children: [
                            if (index > 0) const SizedBox(height: 12),
                            _buildMenuCard(
                              context: context,
                              icon: item.icon,
                              title: item.title,
                              subtitle: item.subtitle,
                              onTap: item.onTap,
                              gradient: item.gradient,
                            ),
                          ],
                        );
                      }),

                      const Spacer(),

                      // 登出按鈕
                      _buildLogoutButton(context),

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

  Widget _buildAppBar(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

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
              onPressed: () => Navigator.pop(context, _hasChanges),
              padding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(width: 12),
          Text('設定', style: textTheme.displaySmall?.copyWith(letterSpacing: 0.5)),
        ],
      ),
    );
  }

  Widget _buildMenuCard({
    required final BuildContext context,
    required final IconData icon,
    required final String title,
    required final String subtitle,
    required final VoidCallback onTap,
    final Gradient? gradient,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

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
                          fontSize: 13, // Keep original size
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

  Widget _buildLogoutButton(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

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
          onTap: () => handleSignOut(context),
          borderRadius: BorderRadius.circular(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.logout_rounded, color: colorScheme.error, size: 24),
              const SizedBox(width: 8),
              Text('登出', style: textTheme.titleSmall?.copyWith(color: colorScheme.error)),
            ],
          ),
        ),
      ),
    );
  }
}
