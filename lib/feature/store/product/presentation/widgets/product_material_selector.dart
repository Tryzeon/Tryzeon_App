import 'package:flutter/material.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/store/product/presentation/sheets/product_material_sheet.dart';

class ProductMaterialSelector extends StatelessWidget {
  const ProductMaterialSelector({super.key, required this.selectedMaterial});

  final ValueNotifier<String?> selectedMaterial;

  Future<void> _openSheet(final BuildContext context) async {
    final result = await ProductMaterialSheet.show(
      context: context,
      initialValue: selectedMaterial.value,
    );
    if (result == null) return;
    selectedMaterial.value = result.value;
  }

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);
    return ValueListenableBuilder<String?>(
      valueListenable: selectedMaterial,
      builder: (final context, final value, final _) {
        final isEmpty = value == null || value.isEmpty;
        return InkWell(
          onTap: () => _openSheet(context),
          borderRadius: AppRadius.inputAll,
          child: InputDecorator(
            decoration: const InputDecoration(),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    isEmpty ? '選擇或輸入材質' : value,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isEmpty ? theme.colorScheme.onSurfaceVariant : null,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
