import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/store/product/presentation/mappers/product_sort_field_ui_mapper.dart';
import 'package:tryzeon/feature/store/product/presentation/state/product_sort_condition.dart';
import 'package:tryzeon/feature/store/product/providers/store_product_providers.dart';

class ProductSortSheet extends HookConsumerWidget {
  const ProductSortSheet({super.key});

  static Future<void> show(final BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (final _) => const ProductSortSheet(),
    );
  }

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final currentQuery = ref.read(productQueryProvider);
    final selectedKey = useState<SortKey>(currentQuery.sort.key);
    final selectedAscending = useState<bool>(currentQuery.sort.ascending);

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    void applySort(final SortKey key, final bool ascending) {
      ref
          .read(productQueryProvider.notifier)
          .updateSort(SortCondition(key: key, ascending: ascending));
    }

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Text('排序', style: textTheme.titleLarge),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: SegmentedButton<bool>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment<bool>(
                  value: false,
                  label: Text(selectedKey.value.descendingLabel),
                ),
                ButtonSegment<bool>(
                  value: true,
                  label: Text(selectedKey.value.ascendingLabel),
                ),
              ],
              selected: {selectedAscending.value},
              onSelectionChanged: (final s) {
                final v = s.first;
                selectedAscending.value = v;
                applySort(selectedKey.value, v);
              },
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(),
          const SizedBox(height: AppSpacing.sm),
          ...allSortKeys.map(
            (final key) => ListTile(
              title: Text(key.label),
              selected: key == selectedKey.value,
              trailing: key == selectedKey.value
                  ? Icon(Icons.check, color: colorScheme.primary)
                  : null,
              onTap: () {
                if (key == selectedKey.value) return;
                selectedKey.value = key;
                applySort(key, selectedAscending.value);
              },
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}
