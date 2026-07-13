import 'package:flutter/material.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/common/clothing_style/domain/entities/clothing_style.dart';

/// Presentational 風格圖片格狀多選元件。無狀態、不依賴任何 provider,
/// 由呼叫端傳入目前選取集合與 toggle callback,供 onboarding 與設定頁共用。
/// 本元件為可捲動 GridView,呼叫端通常以 `Expanded` 包裹。
class StylePreferenceGrid extends StatelessWidget {
  const StylePreferenceGrid({super.key, required this.selected, required this.onToggle});

  final Set<ClothingStyle> selected;
  final void Function(ClothingStyle style) onToggle;

  @override
  Widget build(final BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return GridView.builder(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.mdLg,
      ),
      itemCount: ClothingStyle.values.length,
      itemBuilder: (final context, final index) {
        final style = ClothingStyle.values[index];
        final isSelected = selected.contains(style);

        return GestureDetector(
          onTap: () => onToggle(style),
          child: Column(
            children: [
              Expanded(
                child: AnimatedContainer(
                  duration: AppDuration.standard,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.outline.withValues(alpha: AppOpacity.strong),
                      width: isSelected ? AppStroke.regular : AppStroke.thin,
                    ),
                    borderRadius: AppRadius.cardAll,
                  ),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: AppRadius.inputAll,
                        child: Image.asset(
                          'assets/images/onboarding/${style.value}.webp',
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          errorBuilder: (final context, final error, final stackTrace) {
                            return Container(
                              color: colorScheme.surfaceContainerHighest,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.image_not_supported_outlined,
                                    color: colorScheme.outline,
                                    size: 32,
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(style.value, style: textTheme.labelSmall),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      if (isSelected)
                        Positioned(
                          top: AppSpacing.sm,
                          right: AppSpacing.sm,
                          child: Container(
                            padding: const EdgeInsets.all(AppSpacing.xs),
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.check_rounded,
                              color: colorScheme.onPrimary,
                              size: 16,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                style.label,
                style: textTheme.bodySmall?.copyWith(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }
}
