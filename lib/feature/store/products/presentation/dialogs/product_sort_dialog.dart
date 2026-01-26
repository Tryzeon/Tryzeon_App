import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/feature/store/products/domain/value_objects/product_sort_condition.dart';
import 'package:tryzeon/feature/store/products/presentation/mapper/product_sort_field_ui_mapper.dart';
import 'package:tryzeon/feature/store/products/providers/store_products_providers.dart';

void showSortOptionsDialog(final BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (final context) => const _SortOptionsDialogContent(),
  );
}

class _SortOptionsDialogContent extends ConsumerWidget {
  const _SortOptionsDialogContent();

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final sortCondition = ref.watch(productSortConditionProvider);
    final sortField = sortCondition.field;
    final ascending = sortCondition.ascending;

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    void handleSortChange(final SortField newValue) {
      ref.read(productSortConditionProvider.notifier).state = SortCondition(
        field: newValue,
        ascending: ascending,
      );
    }

    void handleAscendingChange(final bool value) {
      ref.read(productSortConditionProvider.notifier).state = SortCondition(
        field: sortField,
        ascending: value,
      );
    }

    Widget buildHeader() {
      return Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: colorScheme.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.sort_rounded, color: colorScheme.onPrimary, size: 24),
          ),
          const SizedBox(width: 12),
          Text('排序方式', style: textTheme.titleLarge),
        ],
      );
    }

    Widget buildSortOptions() {
      return RadioGroup<SortField>(
        groupValue: sortField,
        onChanged: (final val) {
          if (val != null) {
            handleSortChange(val);
          }
        },
        child: Column(
          children: SortField.values.map((final field) {
            final isSelected = sortField == field;

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: isSelected ? colorScheme.primary.withValues(alpha: 0.1) : null,
                borderRadius: BorderRadius.circular(12),
                border: isSelected
                    ? Border.all(color: colorScheme.primary, width: 2)
                    : null,
              ),
              child: InkWell(
                onTap: () => handleSortChange(field),
                borderRadius: BorderRadius.circular(12),
                child: ListTile(
                  title: Text(
                    field.label,
                    style: textTheme.titleSmall?.copyWith(
                      color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                    ),
                  ),
                  leading: Radio<SortField>(
                    value: field,
                    fillColor: WidgetStateProperty.resolveWith((final states) {
                      if (states.contains(WidgetState.selected)) {
                        return colorScheme.primary;
                      }
                      return null;
                    }),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      );
    }

    Widget buildAscendingSwitch() {
      return Container(
        decoration: BoxDecoration(
          color: colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: SwitchListTile(
          title: Text(
            '排序轉換',
            style: textTheme.labelLarge?.copyWith(color: colorScheme.onSurface),
          ),
          value: ascending,
          activeTrackColor: colorScheme.primary,
          onChanged: handleAscendingChange,
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      padding: EdgeInsets.only(
        top: 24,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildHeader(),
            const SizedBox(height: 24),
            buildSortOptions(),
            const SizedBox(height: 16),
            buildAscendingSwitch(),
          ],
        ),
      ),
    );
  }
}
