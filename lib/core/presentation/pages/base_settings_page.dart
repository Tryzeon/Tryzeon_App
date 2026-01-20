import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:tryzeon/core/utils/app_logger.dart';

/// 設定頁面的選單項目資料模型
class SettingsMenuItem {
  const SettingsMenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.color,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? color;
}

/// 共用的設定頁面骨架
///
/// 負責統一的 UI 風格，包含背景漸層、AppBar、選單列表樣式與登出按鈕樣式。
/// 具體的業務邏輯（如導航、登出行為）由外部傳入。
class SettingsPageScaffold extends HookConsumerWidget {
  const SettingsPageScaffold({
    super.key,
    required this.menuItems,
    required this.onLogout,
    required this.onBack,
  });

  final List<SettingsMenuItem> menuItems;
  final VoidCallback onLogout;
  final VoidCallback onBack;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(color: colorScheme.surface),
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
                            _MenuCard(item: item),
                          ],
                        );
                      }),

                      const Spacer(),

                      // 登出按鈕
                      _LogoutButton(onTap: onLogout),

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
              onPressed: onBack,
              padding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onLongPress: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (final context) => TalkerScreen(talker: AppLogger.talker),
                ),
              );
            },
            child: Text(
              '設定',
              style: textTheme.displaySmall?.copyWith(letterSpacing: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({required this.item});

  final SettingsMenuItem item;

  @override
  Widget build(final BuildContext context) {
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
          onTap: item.onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: item.color ?? colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(item.icon, color: colorScheme.primary, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.title, style: textTheme.titleSmall),
                      const SizedBox(height: 4),
                      Text(
                        item.subtitle,
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
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(final BuildContext context) {
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
          onTap: onTap,
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
