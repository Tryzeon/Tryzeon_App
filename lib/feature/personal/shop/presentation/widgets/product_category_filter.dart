import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/presentation/widgets/error_view.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/common/product_categories/domain/entities/product_category.dart';

class ProductCategoryFilter extends StatelessWidget {
  const ProductCategoryFilter({
    super.key,
    required this.categoriesAsync,
    required this.selectedCategoryIds,
    required this.onCategoryToggle,
    required this.onRetry,
  });

  final AsyncValue<List<ProductCategory>> categoriesAsync;
  final Set<String> selectedCategoryIds;
  final Function(String) onCategoryToggle;
  final VoidCallback onRetry;

  @override
  Widget build(final BuildContext context) {
    // Priority 1: show data if available (even during loading or error).
    if (categoriesAsync.hasValue) {
      final categories = categoriesAsync.value!;
      if (categories.isEmpty) return const SizedBox.shrink();

      return SizedBox(
        height: 96,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          itemCount: categories.length,
          separatorBuilder: (final context, final index) =>
              const SizedBox(width: AppSpacing.xxs),
          itemBuilder: (final context, final index) {
            final category = categories[index];
            return _CategoryCard(
              category: category,
              isSelected: selectedCategoryIds.contains(category.id),
              onTap: () {
                HapticFeedback.selectionClick();
                onCategoryToggle(category.id);
              },
            );
          },
        ),
      );
    }

    // Priority 2: loading without data.
    if (categoriesAsync.isLoading) {
      return const SizedBox(
        height: 96,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    // Priority 3: error without data.
    return ErrorView(onRetry: onRetry, isCompact: true);
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  final ProductCategory category;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final imageUrl = category.imageUrl;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Card(
            color: isSelected
                ? colorScheme.primaryContainer
                : colorScheme.surfaceContainerHighest,
            shape: RoundedRectangleBorder(
              borderRadius: AppRadius.dialogAll,
              side: isSelected
                  ? BorderSide(color: colorScheme.primary, width: AppStroke.regular)
                  : BorderSide.none,
            ),
            child: SizedBox(
              width: 56,
              height: 56,
              child: ClipRRect(
                borderRadius: AppRadius.dialogAll,
                child: (imageUrl != null && imageUrl.isNotEmpty)
                    ? CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        memCacheWidth: 180,
                        memCacheHeight: 180,
                        fadeInDuration: Duration.zero,
                        fadeOutDuration: Duration.zero,
                        placeholder: (final context, final url) => Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: AppStroke.regular,
                              color: colorScheme.outline,
                            ),
                          ),
                        ),
                        errorWidget: (final context, final url, final error) => Icon(
                          Icons.image_not_supported_outlined,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      )
                    : Icon(
                        Icons.image_not_supported_outlined,
                        color: colorScheme.onSurfaceVariant,
                      ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          SizedBox(
            width: 82,
            child: Text(
              category.name,
              style: textTheme.labelSmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
