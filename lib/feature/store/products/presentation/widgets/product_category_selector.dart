import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/common/product_categories/domain/entities/product_category.dart';
import 'package:tryzeon/feature/store/products/presentation/sheets/product_category_sheet.dart';

class ProductCategorySelector extends HookWidget {
  const ProductCategorySelector({
    super.key,
    required this.categories,
    required this.selectedCategoryId,
    this.onChanged,
    this.hasError = false,
  });

  final List<ProductCategory> categories;
  final ValueNotifier<String?> selectedCategoryId;
  final ValueChanged<String>? onChanged;
  final bool hasError;

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final inputTheme = theme.inputDecorationTheme;
    final selectedNotifier = useListenable(selectedCategoryId);
    final selectedId = selectedNotifier.value;

    final selectedName = categories
        .where((final c) => c.id == selectedId)
        .firstOrNull
        ?.name;

    Future<void> openSheet() async {
      final result = await ProductCategorySheet.show(
        context: context,
        categories: categories,
        initialId: selectedId,
      );
      if (result == null) return;
      if (onChanged != null) {
        onChanged!(result);
      } else {
        selectedCategoryId.value = result;
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
              child: Text(
                selectedName ?? '選擇商品分類',
                style: textTheme.bodyMedium?.copyWith(
                  color: selectedName == null ? colorScheme.onSurfaceVariant : null,
                ),
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
