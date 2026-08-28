import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/common/product_attributes/domain/entities/wardrobe_category.dart';
import 'package:tryzeon/feature/common/product_attributes/presentation/product_attributes_extensions.dart';
import 'package:tryzeon/feature/common/product_category/domain/entities/product_category.dart';

class ProductCategorySheet extends HookWidget {
  const ProductCategorySheet({super.key, required this.categories, this.initialId});

  final List<ProductCategory> categories;
  final String? initialId;

  static Future<String?> show({
    required final BuildContext context,
    required final List<ProductCategory> categories,
    final String? initialId,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (final _) =>
          ProductCategorySheet(categories: categories, initialId: initialId),
    );
  }

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

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
            (final g) => g.value.any((final c) => c.id == initialId),
            orElse: () => groups.isEmpty
                ? const MapEntry(WardrobeCategory.others, [])
                : groups.first,
          )
          .key,
    );

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
              AppSpacing.lg,
              AppSpacing.md,
            ),
            child: Row(children: [Text('選擇分類', style: textTheme.titleMedium)]),
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
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              children: [
                for (final category in activeCategories)
                  ListTile(
                    title: Text(category.name, style: theme.textTheme.bodyLarge),
                    trailing: category.id == initialId
                        ? Icon(Icons.check_rounded, color: colorScheme.primary)
                        : null,
                    onTap: () => Navigator.of(context).pop(category.id),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
