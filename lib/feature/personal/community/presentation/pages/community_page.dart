import 'package:flutter/material.dart';

class CommunityPage extends StatelessWidget {
  const CommunityPage({super.key});

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.surface,
            Color.alphaBlend(
              colorScheme.surface.withValues(alpha: 0.2),
              colorScheme.surface,
            ),
            Color.alphaBlend(
              colorScheme.primary.withValues(alpha: 0.1),
              colorScheme.surface,
            ),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 圖標
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [colorScheme.primary, colorScheme.secondary],
                ),
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
            ShaderMask(
              shaderCallback: (final bounds) => LinearGradient(
                colors: [colorScheme.primary, colorScheme.secondary],
              ).createShader(bounds),
              child: Text(
                '社群功能',
                style: textTheme.displaySmall?.copyWith(
                  color: Colors.white,
                  letterSpacing: 1.5,
                ),
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
                    _buildFeatureItem(
                      context: context,
                      icon: Icons.share_outlined,
                      title: '分享穿搭',
                      subtitle: '與朋友分享你的時尚品味',
                    ),
                    const SizedBox(height: 16),
                    _buildFeatureItem(
                      context: context,
                      icon: Icons.favorite_outline_rounded,
                      title: '按讚收藏',
                      subtitle: '收藏喜歡的穿搭靈感',
                    ),
                    const SizedBox(height: 16),
                    _buildFeatureItem(
                      context: context,
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

  Widget _buildFeatureItem({
    required final BuildContext context,
    required final IconData icon,
    required final String title,
    required final String subtitle,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

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
}
