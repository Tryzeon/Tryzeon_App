import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

const double kMaxPrice = 3000;

class FilterDialog {
  FilterDialog({
    required this.context,
    this.minPrice,
    this.maxPrice,
    required this.onApply,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (final BuildContext context) {
        return _FilterDialogContent(
          minPrice: minPrice,
          maxPrice: maxPrice,
          onApply: onApply,
        );
      },
    );
  }
  final BuildContext context;
  final int? minPrice;
  final int? maxPrice;
  final Function(int? minPrice, int? maxPrice) onApply;
}

class _FilterDialogContent extends HookConsumerWidget {
  const _FilterDialogContent({this.minPrice, this.maxPrice, required this.onApply});
  final int? minPrice;
  final int? maxPrice;
  final Function(int? minPrice, int? maxPrice) onApply;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final initialMin = minPrice?.toDouble() ?? 0;
    final initialMax = maxPrice?.toDouble() ?? kMaxPrice;

    final priceRange = useState(RangeValues(initialMin, initialMax));
    final currentMinPrice = useState(minPrice);
    final currentMaxPrice = useState(maxPrice);

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    void applyFilters() {
      onApply(currentMinPrice.value, currentMaxPrice.value);
      Navigator.pop(context);
    }

    void resetFilters() {
      currentMinPrice.value = null;
      currentMaxPrice.value = null;
      priceRange.value = const RangeValues(0, kMaxPrice);
      applyFilters();
    }

    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 標題
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.tune_rounded, color: colorScheme.onPrimary, size: 24),
                ),
                const SizedBox(width: 12),
                Text('篩選條件', style: textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 24),

            // 價格範圍
            Text('價格範圍', style: textTheme.titleMedium),
            const SizedBox(height: 8),
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
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: colorScheme.primary,
                inactiveTrackColor: colorScheme.primary.withValues(alpha: 0.2),
                thumbColor: colorScheme.primary,
                overlayColor: colorScheme.primary.withValues(alpha: 0.2),
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
              ),
              child: RangeSlider(
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
            ),

            const SizedBox(height: 24),

            // 按鈕
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      border: Border.all(color: colorScheme.primary, width: 2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: resetFilters,
                        borderRadius: BorderRadius.circular(12),
                        child: Center(
                          child: Text(
                            '清除',
                            style: textTheme.titleSmall?.copyWith(
                              color: colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: applyFilters,
                        borderRadius: BorderRadius.circular(12),
                        child: Center(
                          child: Text(
                            '套用',
                            style: textTheme.titleSmall?.copyWith(
                              color: colorScheme.onPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
