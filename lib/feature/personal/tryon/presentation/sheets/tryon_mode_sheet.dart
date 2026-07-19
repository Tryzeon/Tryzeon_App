import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tryzeon/core/router/app_routes.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_mode.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/sheets/video_prompt_customize_sheet.dart';

class TryOnModeSheet extends StatelessWidget {
  const TryOnModeSheet({
    super.key,
    required this.hasVideoAccess,
    required this.onModeSelected,
  });

  final bool hasVideoAccess;
  final ValueChanged<TryOnMode> onModeSelected;

  /// Show the bottom sheet. Returns the selected TryOnMode or null if dismissed.
  static Future<void> show({
    required final BuildContext context,
    required final bool hasVideoAccess,
    required final ValueChanged<TryOnMode> onModeSelected,
  }) {
    return showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      showDragHandle: true,
      builder: (final context) =>
          TryOnModeSheet(hasVideoAccess: hasVideoAccess, onModeSelected: onModeSelected),
    );
  }

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      bottom: true,
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.mdLg),
              child: Row(
                children: [
                  Icon(Icons.auto_awesome, color: colorScheme.onSurface, size: 24),
                  const SizedBox(width: AppSpacing.smMd),
                  Text('選擇試穿方式', style: textTheme.titleLarge),
                ],
              ),
            ),

            // ③ Image Try-On Card
            _ModeCard(
              icon: Icons.photo_outlined,
              title: '圖片試穿',
              subtitle: '讓 AI 幫你穿上這件衣服',
              isLocked: false,
              isNew: false,
              onTap: () {
                Navigator.pop(context);
                onModeSelected(TryOnMode.image);
              },
              colorScheme: colorScheme,
              textTheme: textTheme,
            ),

            const SizedBox(height: AppSpacing.smMd),

            // ④ Video Try-On Card
            _ModeCard(
              icon: Icons.videocam_outlined,
              title: '影片試穿',
              subtitle: '生成你的走秀影片',
              isLocked: !hasVideoAccess,
              isNew: true,
              onTap: () {
                Navigator.pop(context);
                onModeSelected(TryOnMode.video);
              },
              onCustomize: () {
                VideoPromptCustomizeSheet.show(context);
              },
              colorScheme: colorScheme,
              textTheme: textTheme,
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isLocked,
    required this.isNew,
    required this.onTap,
    required this.colorScheme,
    required this.textTheme,
    this.onCustomize,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool isLocked;
  final bool isNew;
  final VoidCallback onTap;
  final ColorScheme colorScheme;
  final TextTheme textTheme;
  final VoidCallback? onCustomize;

  @override
  Widget build(final BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: isLocked ? null : onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.mdLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Icon circle
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: colorScheme.onPrimaryContainer, size: 18),
                  ),
                  const SizedBox(width: AppSpacing.md),

                  // Title + subtitle
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (isLocked)
                              Padding(
                                padding: const EdgeInsets.only(right: AppSpacing.sm),
                                child: Icon(
                                  Icons.lock_rounded,
                                  size: 14,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            Text(title, style: textTheme.titleSmall),
                            if (isNew) ...[
                              const SizedBox(width: AppSpacing.sm),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm,
                                  vertical: AppSpacing.xxs,
                                ),
                                decoration: BoxDecoration(
                                  color: colorScheme.primary,
                                  borderRadius: AppRadius.buttonAll,
                                ),
                                child: Text(
                                  'NEW',
                                  style: textTheme.labelSmall?.copyWith(
                                    color: colorScheme.onPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          subtitle,
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Customize button (pencil) — only when unlocked and callback provided
                  if (!isLocked && onCustomize != null)
                    GestureDetector(
                      onTap: onCustomize,
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Icon(
                          Icons.edit_outlined,
                          size: 20,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),

                  // Chevron (only show when unlocked)
                  if (!isLocked)
                    Icon(
                      Icons.chevron_right_rounded,
                      color: colorScheme.onSurfaceVariant,
                    ),
                ],
              ),

              // ⑤ Upgrade button (non-Max only)
              if (isLocked) ...[
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      context.push(AppRoutes.personalSubscription);
                    },
                    icon: const Icon(Icons.auto_awesome, size: 16),
                    label: const Text('升級至 Max 方案解鎖'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
