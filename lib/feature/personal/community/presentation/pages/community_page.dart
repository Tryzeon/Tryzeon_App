import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class CommunityPage extends HookConsumerWidget {
  const CommunityPage({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    Widget buildFeatureItem({
      required final IconData icon,
      required final String title,
      required final String subtitle,
    }) {
      return Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: colorScheme.tertiary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: colorScheme.tertiary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: textTheme.titleSmall),
                Text(
                  subtitle,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Container(
      decoration: BoxDecoration(color: colorScheme.surface),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 圖標
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: colorScheme.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(
                Icons.people_outline_rounded,
                size: 60,
                color: colorScheme.onPrimary,
              ),
            ),
            const SizedBox(height: 32),

            // 標題
            Text(
              '社群功能',
              style: textTheme.displaySmall?.copyWith(
                color: colorScheme.primary,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 16),

            // 副標題
            Text(
              '稍後推出，敬請期待',
              style: textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 48),

            // 裝飾卡片
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: colorScheme.surface.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    buildFeatureItem(
                      icon: Icons.share_outlined,
                      title: '分享穿搭',
                      subtitle: '與朋友分享你的時尚品味',
                    ),
                    const SizedBox(height: 16),
                    buildFeatureItem(
                      icon: Icons.favorite_outline_rounded,
                      title: '按讚收藏',
                      subtitle: '收藏喜歡的穿搭靈感',
                    ),
                    const SizedBox(height: 16),
                    buildFeatureItem(
                      icon: Icons.comment_outlined,
                      title: '互動交流',
                      subtitle: '與其他用戶交流心得',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
