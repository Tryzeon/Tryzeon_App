import 'package:flutter/material.dart';

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

class _FilterDialogContent extends StatefulWidget {
  const _FilterDialogContent({
    this.minPrice,
    this.maxPrice,
    required this.onApply,
  });
  final int? minPrice;
  final int? maxPrice;
  final Function(int? minPrice, int? maxPrice) onApply;

  @override
  State<_FilterDialogContent> createState() => _FilterDialogContentState();
}

class _FilterDialogContentState extends State<_FilterDialogContent> {
  late RangeValues _priceRange;
  late int? _minPrice;
  late int? _maxPrice;

  @override
  void initState() {
    super.initState();
    _minPrice = widget.minPrice;
    _maxPrice = widget.maxPrice;
    _priceRange = RangeValues(
      widget.minPrice?.toDouble() ?? 0,
      widget.maxPrice?.toDouble() ?? kMaxPrice,
    );
  }

  void _resetFilters() {
    setState(() {
      _minPrice = null;
      _maxPrice = null;
      _priceRange = const RangeValues(0, kMaxPrice);
    });
    _applyFilters();
  }

  void _applyFilters() {
    widget.onApply(_minPrice, _maxPrice);
    Navigator.pop(context);
  }

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
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
                    gradient: LinearGradient(
                      colors: [colorScheme.primary, colorScheme.secondary],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.tune_rounded,
                    color: colorScheme.onPrimary,
                    size: 24,
                  ),
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
                  '\$${_priceRange.start.round()}',
                  style: textTheme.labelLarge?.copyWith(
                    color: colorScheme.primary,
                  ),
                ),
                Text(
                  _priceRange.end.round() >= kMaxPrice
                      ? '\$${kMaxPrice.round()}+'
                      : '\$${_priceRange.end.round()}',
                  style: textTheme.labelLarge?.copyWith(
                    color: colorScheme.primary,
                  ),
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
                values: _priceRange,
                min: 0,
                max: kMaxPrice,
                divisions: 100,
                onChanged: (final RangeValues values) {
                  setState(() {
                    _priceRange = values;
                    _minPrice = values.start.round();
                    _maxPrice = values.end >= kMaxPrice
                        ? null
                        : values.end.round();
                  });
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
                        onTap: _resetFilters,
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
                      gradient: LinearGradient(
                        colors: [colorScheme.primary, colorScheme.secondary],
                      ),
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
                        onTap: _applyFilters,
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
