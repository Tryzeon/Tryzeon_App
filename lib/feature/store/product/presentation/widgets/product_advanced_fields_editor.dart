import 'package:flutter/material.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/common/clothing_style/domain/entities/clothing_style.dart';
import 'package:tryzeon/feature/common/product_attributes/domain/entities/product_attributes.dart';
import 'package:tryzeon/feature/store/product/presentation/widgets/product_elasticity_selector.dart';
import 'package:tryzeon/feature/store/product/presentation/widgets/product_fit_selector.dart';
import 'package:tryzeon/feature/store/product/presentation/widgets/product_material_selector.dart';
import 'package:tryzeon/feature/store/product/presentation/widgets/product_season_selector.dart';
import 'package:tryzeon/feature/store/product/presentation/widgets/product_style_selector.dart';
import 'package:tryzeon/feature/store/product/presentation/widgets/product_thickness_selector.dart';

class ProductAdvancedFieldsEditor extends StatelessWidget {
  const ProductAdvancedFieldsEditor({
    super.key,
    required this.selectedMaterial,
    required this.selectedFit,
    required this.selectedElasticity,
    required this.selectedThickness,
    required this.selectedStyles,
    required this.selectedSeasons,
    this.controller,
  });

  final ValueNotifier<String?> selectedMaterial;
  final ValueNotifier<ProductFit?> selectedFit;
  final ValueNotifier<ProductElasticity?> selectedElasticity;
  final ValueNotifier<ProductThickness?> selectedThickness;
  final ValueNotifier<Set<ClothingStyle>?> selectedStyles;
  final ValueNotifier<Set<ProductSeason>?> selectedSeasons;

  final ExpansibleController? controller;

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);

    return ExpansionTile(
      controller: controller,
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(top: AppSpacing.sm),
      expandedCrossAxisAlignment: CrossAxisAlignment.start,
      title: Text('進階資料', style: theme.textTheme.titleSmall),
      subtitle: Text(
        '展開以填寫更多選填屬性',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      children: [
        const _FieldLabel('風格標籤'),
        ProductStyleSelector(selectedStyles: selectedStyles),
        const SizedBox(height: AppSpacing.md),
        const _FieldLabel('季節'),
        ProductSeasonSelector(selectedSeasons: selectedSeasons),
        const SizedBox(height: AppSpacing.md),
        const _FieldLabel('材質'),
        ProductMaterialSelector(selectedMaterial: selectedMaterial),
        const SizedBox(height: AppSpacing.md),
        const _FieldLabel('彈性'),
        ProductElasticitySelector(selectedElasticity: selectedElasticity),
        const SizedBox(height: AppSpacing.md),
        const _FieldLabel('版型'),
        ProductFitSelector(selectedFit: selectedFit),
        const SizedBox(height: AppSpacing.md),
        const _FieldLabel('厚度'),
        ProductThicknessSelector(selectedThickness: selectedThickness),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);
    final labelStyle = theme.textTheme.labelMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Text(text, style: labelStyle),
    );
  }
}
