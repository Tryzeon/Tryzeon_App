import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/common/product_attributes/domain/entities/product_attributes.dart';
import 'package:tryzeon/feature/common/product_attributes/presentation/product_attributes_extensions.dart';

class ProductSeasonSelector extends HookWidget {
  const ProductSeasonSelector({super.key, required this.selectedSeasons});

  final ValueNotifier<List<ProductSeason>?> selectedSeasons;

  @override
  Widget build(final BuildContext context) {
    final current = useListenable(selectedSeasons);
    final selected = current.value ?? const [];

    void toggle(final ProductSeason season) {
      final list = [...selected];
      if (list.contains(season)) {
        list.remove(season);
      } else {
        list.add(season);
      }
      selectedSeasons.value = list.isEmpty ? null : list;
    }

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xs,
      children: ProductSeason.values
          .map(
            (final season) => FilterChip(
              label: Text(season.label),
              selected: selected.contains(season),
              onSelected: (final _) => toggle(season),
            ),
          )
          .toList(),
    );
  }
}
