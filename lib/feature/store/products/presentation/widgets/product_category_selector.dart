import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/common/product_categories/domain/entities/product_category.dart';
import 'package:tryzeon/feature/store/products/presentation/sheets/product_category_sheet.dart';

class ProductCategorySelector extends HookWidget {
  const ProductCategorySelector({
    super.key,
    required this.categories,
    required this.selectedCategoryIds,
    this.onChanged,
    this.hasError = false,
  });

  final List<ProductCategory> categories;
  final ValueNotifier<Set<String>> selectedCategoryIds;
  final ValueChanged<Set<String>>? onChanged;
  final bool hasError;

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final inputTheme = theme.inputDecorationTheme;
    final selectedNotifier = useListenable(selectedCategoryIds);
    final selectedIds = selectedNotifier.value;

    final categoryMap = useMemoized(() => {for (final c in categories) c.id: c.name}, [
      categories,
    ]);

    String displayName(final String id) => categoryMap[id] ?? id;

    Future<void> openSheet() async {
      final result = await ProductCategorySheet.show(
        context: context,
        categories: categories,
        initialIds: selectedIds,
      );
      if (result == null) return;
      if (onChanged != null) {
        onChanged!(result);
      } else {
        selectedCategoryIds.value = result;
      }
    }

    return InkWell(
      onTap: openSheet,
      borderRadius: AppRadius.inputAll,
      child: InputDecorator(
        decoration: const InputDecoration()
            .applyDefaults(inputTheme)
            .copyWith(
              border: hasError ? inputTheme.errorBorder : null,
              enabledBorder: hasError ? inputTheme.errorBorder : null,
              focusedBorder: hasError ? inputTheme.focusedErrorBorder : null,
            ),
        child: Row(
          children: [
            Expanded(
              child: selectedIds.isEmpty
                  ? Text(
                      '選擇商品分類',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    )
                  : Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.xs,
                      children: selectedIds
                          .map(
                            (final id) => Chip(
                              label: Text(displayName(id)),
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                            ),
                          )
                          .toList(),
                    ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Icon(Icons.keyboard_arrow_down_rounded, color: colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
