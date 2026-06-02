import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
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
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final selection = useState<Set<String>>(initialIds);
    final searchController = useTextEditingController();
    useListenable(searchController);

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

    final query = searchController.text.trim().toLowerCase();
    final visible = query.isEmpty
        ? categories
        : categories.where((final c) => c.name.toLowerCase().contains(query)).toList();

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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('選擇分類', style: textTheme.titleMedium),
                TextButton(onPressed: done, child: const Text('完成')),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: '搜尋分類...',
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: colorScheme.onSurfaceVariant,
                  size: 20,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: visible.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Text(
                        '沒有符合的分類',
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                    itemCount: visible.length,
                    itemBuilder: (final context, final index) {
                      final category = visible[index];
                      final isSelected = selection.value.contains(category.id);
                      return InkWell(
                        onTap: () => toggleSelection(category.id),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                            vertical: AppSpacing.xs,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(category.name, style: textTheme.bodyLarge),
                              ),
                              Checkbox(
                                value: isSelected,
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                onChanged: (final _) => toggleSelection(category.id),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
