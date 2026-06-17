import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/common/store/domain/entities/store_channel.dart';
import 'package:tryzeon/feature/personal/shop/providers/shop_filter_provider.dart';

const double kMaxPrice = 3000;

class FilterSheet extends HookConsumerWidget {
  const FilterSheet({super.key});

  static Future<void> show({required final BuildContext context}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      showDragHandle: true,
      builder: (final BuildContext context) => const FilterSheet(),
    );
  }

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final initial = useMemoized(() => ref.read(shopFilterProvider));

    final priceRange = useState(
      RangeValues(
        initial.minPrice?.toDouble() ?? 0,
        initial.maxPrice?.toDouble() ?? kMaxPrice,
      ),
    );
    final currentMinPrice = useState(initial.minPrice);
    final currentMaxPrice = useState(initial.maxPrice);
    final selectedChannels = useState<Set<StoreChannel>>({...?initial.channels});

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    void applyFilters() {
      ref
          .read(shopFilterProvider.notifier)
          .setPriceRange(min: currentMinPrice.value, max: currentMaxPrice.value);

      ref.read(shopFilterProvider.notifier).setChannels(selectedChannels.value);
      Navigator.of(context, rootNavigator: true).pop();
    }

    void resetFilters() {
      currentMinPrice.value = null;
      currentMaxPrice.value = null;
      priceRange.value = const RangeValues(0, kMaxPrice);
      selectedChannels.value = {};
      ref.read(shopFilterProvider.notifier).reset();
    }

    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        bottom: true,
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 標題
              Text('篩選條件', style: textTheme.titleLarge),
              const SizedBox(height: AppSpacing.lg),

              // 販售通路
              Text('販售通路', style: textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                children: StoreChannel.values.map((final channel) {
                  final isSelected = selectedChannels.value.contains(channel);
                  return FilterChip(
                    label: Text(channel.label),
                    selected: isSelected,
                    onSelected: (final v) {
                      final next = {...selectedChannels.value};
                      if (v) {
                        next.add(channel);
                      } else {
                        next.remove(channel);
                      }
                      selectedChannels.value = next;
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.lg),

              // 價格範圍
              Text('價格範圍', style: textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '\$${priceRange.value.start.round()}',
                    style: textTheme.labelLarge?.copyWith(color: colorScheme.primary),
                  ),
                  Text(
                    priceRange.value.end.round() >= kMaxPrice
                        ? '\$${kMaxPrice.round()}+'
                        : '\$${priceRange.value.end.round()}',
                    style: textTheme.labelLarge?.copyWith(color: colorScheme.primary),
                  ),
                ],
              ),
              RangeSlider(
                values: priceRange.value,
                min: 0,
                max: kMaxPrice,
                divisions: 100,
                onChanged: (final RangeValues values) {
                  priceRange.value = values;
                  currentMinPrice.value = values.start.round();
                  currentMaxPrice.value = values.end >= kMaxPrice
                      ? null
                      : values.end.round();
                },
              ),

              const SizedBox(height: AppSpacing.lg),

              // 按鈕
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: resetFilters,
                      child: const Text('清除'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: FilledButton(
                      onPressed: applyFilters,
                      child: const Text('套用'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
