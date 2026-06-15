import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/common/product_attributes/entities/wardrobe_category.dart';
import 'package:tryzeon/feature/common/product_attributes/presentation/product_attributes_extensions.dart';
import 'package:tryzeon/feature/common/product_categories/domain/entities/product_category.dart';

class ProductCategorySheet extends HookWidget {
  const ProductCategorySheet({
    super.key,
    required this.categories,
    required this.initialIds,
  });

  final List<ProductCategory> categories;
  final Set<String> initialIds;

  static Future<Set<String>?> show({
    required final BuildContext context,
    required final List<ProductCategory> categories,
    required final Set<String> initialIds,
  }) {
    return showModalBottomSheet<Set<String>>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (final _) =>
          ProductCategorySheet(categories: categories, initialIds: initialIds),
    );
  }

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    final selection = useState<Set<String>>(initialIds);

    final groups = useMemoized(() {
      final byCategory = <WardrobeCategory, List<ProductCategory>>{};
      for (final c in categories) {
        (byCategory[c.wardrobeCategory!] ??= []).add(c);
      }
      return [
        for (final wc in WardrobeCategory.values)
          if (byCategory[wc] case final items?) MapEntry(wc, items),
      ];
    }, [categories]);

    final activeGroup = useState<WardrobeCategory?>(null);

    void toggleSelection(final String id) {
      final next = {...selection.value};
      if (next.contains(id)) {
        next.remove(id);
      } else {
        next.add(id);
      }
      selection.value = next;
    }

    void done() => Navigator.of(context).pop(selection.value);

    final active = activeGroup.value;
    final activeCategories = active == null
        ? const <ProductCategory>[]
        : groups.firstWhere((final g) => g.key == active).value;

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.7,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: [
                if (active != null)
                  IconButton(
                    onPressed: () => activeGroup.value = null,
                    icon: const Icon(Icons.arrow_back_rounded),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                if (active != null) const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    active == null ? '選擇分類' : active.displayName,
                    style: textTheme.titleMedium,
                  ),
                ),
                TextButton(onPressed: done, child: const Text('完成')),
              ],
            ),
          ),
          Expanded(
            child: active == null
                ? ListView(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                    children: [
                      for (final group in groups)
                        _GroupRow(
                          wardrobeCategory: group.key,
                          selectedCount: group.value
                              .where((final c) => selection.value.contains(c.id))
                              .length,
                          onTap: () => activeGroup.value = group.key,
                        ),
                    ],
                  )
                : ListView(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                    children: [
                      for (final category in activeCategories)
                        _CategoryRow(
                          category: category,
                          isSelected: selection.value.contains(category.id),
                          onTap: () => toggleSelection(category.id),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _GroupRow extends StatelessWidget {
  const _GroupRow({
    required this.wardrobeCategory,
    required this.selectedCount,
    required this.onTap,
  });

  final WardrobeCategory wardrobeCategory;
  final int selectedCount;
  final VoidCallback onTap;

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                wardrobeCategory.displayName,
                style: textTheme.bodyLarge,
              ),
            ),
            if (selectedCount > 0) ...[
              Text(
                '$selectedCount',
                style: textTheme.labelMedium?.copyWith(
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
            ],
            Icon(
              Icons.keyboard_arrow_right_rounded,
              color: colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  final ProductCategory category;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          children: [
            Expanded(child: Text(category.name, style: textTheme.bodyLarge)),
            Checkbox(
              value: isSelected,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              onChanged: (final _) => onTap(),
            ),
          ],
        ),
      ),
    );
  }
}
