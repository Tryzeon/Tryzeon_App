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

    final activeGroup = useState<WardrobeCategory?>(
      groups
          .firstWhere(
            (final g) => g.value.any((final c) => initialIds.contains(c.id)),
            orElse: () => groups.isEmpty
                ? const MapEntry(WardrobeCategory.others, [])
                : groups.first,
          )
          .key,
    );

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
    final activeCategories = groups
        .firstWhere(
          (final g) => g.key == active,
          orElse: () => const MapEntry(WardrobeCategory.others, []),
        )
        .value;

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.7,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('選擇分類', style: textTheme.titleMedium),
                TextButton(onPressed: done, child: const Text('完成')),
              ],
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              itemCount: groups.length,
              separatorBuilder: (final _, final _) =>
                  const SizedBox(width: AppSpacing.sm),
              itemBuilder: (final context, final index) {
                final group = groups[index];
                return ChoiceChip(
                  label: Text(group.key.displayName),
                  selected: group.key == active,
                  showCheckmark: false,
                  onSelected: (final _) => activeGroup.value = group.key,
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const Divider(height: 1),
          Expanded(
            child: ListView(
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
