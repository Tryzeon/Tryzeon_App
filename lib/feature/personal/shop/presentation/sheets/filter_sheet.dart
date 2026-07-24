import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/common/clothing_style/domain/entities/clothing_style.dart';
import 'package:tryzeon/feature/common/product_attributes/domain/entities/product_attributes.dart';
import 'package:tryzeon/feature/common/product_attributes/presentation/product_attributes_extensions.dart';
import 'package:tryzeon/feature/common/store/domain/entities/store_channel.dart';
import 'package:tryzeon/feature/personal/shop/presentation/widgets/filter_chip_group.dart';
import 'package:tryzeon/feature/personal/shop/providers/shop_filter_provider.dart';

const double kMaxPrice = 3000;

class FilterSheet extends HookConsumerWidget {
  const FilterSheet({super.key});

  static Future<void> show({required final BuildContext context}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      useSafeArea: true,
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
    final selectedFits = useState<Set<ProductFit>>({...?initial.fits});
    final selectedElasticities = useState<Set<ProductElasticity>>({
      ...?initial.elasticities,
    });
    final selectedThicknesses = useState<Set<ProductThickness>>({
      ...?initial.thicknesses,
    });
    final selectedSeasons = useState<Set<ProductSeason>>({...?initial.seasons});
    final selectedStyles = useState<Set<ClothingStyle>>({...?initial.styles});
    final selectedMaterials = useState<Set<String>>({...?initial.materials});

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    void applyFilters() {
      final notifier = ref.read(shopFilterProvider.notifier);
      notifier.setPriceRange(min: currentMinPrice.value, max: currentMaxPrice.value);
      notifier.setChannels(selectedChannels.value);
      notifier.setFits(selectedFits.value);
      notifier.setElasticities(selectedElasticities.value);
      notifier.setThicknesses(selectedThicknesses.value);
      notifier.setSeasons(selectedSeasons.value);
      notifier.setStyles(selectedStyles.value);
      notifier.setMaterials(selectedMaterials.value);
      Navigator.of(context, rootNavigator: true).pop();
    }

    void resetFilters() {
      ref.read(shopFilterProvider.notifier).clearFilters();
      Navigator.of(context, rootNavigator: true).pop();
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
              Text('篩選條件', style: textTheme.titleLarge),
              const SizedBox(height: AppSpacing.lg),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FilterChipGroup<StoreChannel>(
                        title: '販售通路',
                        options: StoreChannel.values,
                        selected: selectedChannels.value,
                        labelOf: (final c) => c.label,
                        onChanged: (final next) => selectedChannels.value = next,
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      Text('價格範圍', style: textTheme.titleMedium),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '\$${priceRange.value.start.round()}',
                            style: textTheme.labelLarge?.copyWith(
                              color: colorScheme.primary,
                            ),
                          ),
                          Text(
                            priceRange.value.end.round() >= kMaxPrice
                                ? '\$${kMaxPrice.round()}+'
                                : '\$${priceRange.value.end.round()}',
                            style: textTheme.labelLarge?.copyWith(
                              color: colorScheme.primary,
                            ),
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

                      FilterChipGroup<ProductFit>(
                        title: '版型',
                        options: ProductFit.values,
                        selected: selectedFits.value,
                        labelOf: (final f) => f.label,
                        onChanged: (final next) => selectedFits.value = next,
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      FilterChipGroup<ProductElasticity>(
                        title: '彈性',
                        options: ProductElasticity.values,
                        selected: selectedElasticities.value,
                        labelOf: (final e) => e.label,
                        onChanged: (final next) => selectedElasticities.value = next,
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      FilterChipGroup<ProductThickness>(
                        title: '厚度',
                        options: ProductThickness.values,
                        selected: selectedThicknesses.value,
                        labelOf: (final t) => t.label,
                        onChanged: (final next) => selectedThicknesses.value = next,
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      FilterChipGroup<ProductSeason>(
                        title: '季節',
                        options: ProductSeason.values,
                        selected: selectedSeasons.value,
                        labelOf: (final s) => s.label,
                        onChanged: (final next) => selectedSeasons.value = next,
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      FilterChipGroup<ClothingStyle>(
                        title: '風格',
                        options: ClothingStyle.values,
                        selected: selectedStyles.value,
                        labelOf: (final s) => s.label,
                        onChanged: (final next) => selectedStyles.value = next,
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      FilterChipGroup<String>(
                        title: '材質',
                        options: kMaterialPresets,
                        selected: selectedMaterials.value,
                        labelOf: (final m) => m,
                        onChanged: (final next) => selectedMaterials.value = next,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
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
                    child: FilledButton(onPressed: applyFilters, child: const Text('套用')),
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
