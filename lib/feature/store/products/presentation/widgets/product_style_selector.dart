import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/common/clothing_style/domain/entities/clothing_style.dart';
import 'package:tryzeon/feature/store/products/presentation/sheets/product_style_sheet.dart';

class ProductStyleSelector extends HookWidget {
  const ProductStyleSelector({super.key, required this.selectedStyles});

  final ValueNotifier<Set<ClothingStyle>?> selectedStyles;

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final current = useListenable(selectedStyles);
    final styles = current.value ?? const <ClothingStyle>{};

    Future<void> openSheet() async {
      final result = await ProductStyleSheet.show(
        context: context,
        initialSelection: styles.toList(),
      );
      if (result == null) return;
      selectedStyles.value = result.isEmpty ? null : result.toSet();
    }

    return InkWell(
      onTap: openSheet,
      borderRadius: AppRadius.inputAll,
      child: InputDecorator(
        decoration: const InputDecoration(),
        child: Row(
          children: [
            Expanded(
              child: styles.isEmpty
                  ? Text(
                      '選擇風格標籤',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    )
                  : Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.xs,
                      children: styles
                          .map(
                            (final s) => Chip(
                              label: Text(s.label),
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
