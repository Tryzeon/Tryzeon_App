import 'package:flutter/material.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/common/product_size/domain/entities/product_size.dart';
import 'package:tryzeon/feature/common/product_size/presentation/mappers/garment_measurement_type_ui_mapper.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/fit_result.dart';
import 'package:tryzeon/feature/personal/shop/presentation/widgets/size_advisor_banner.dart';

class ProductSizeTable extends StatelessWidget {
  const ProductSizeTable({
    required this.sizes,
    required this.columnTypes,
    required this.fitResult,
    super.key,
  });

  final List<ProductSize> sizes;
  final List<GarmentMeasurementType> columnTypes;
  final FitResult fitResult;

  @override
  Widget build(final BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final recommendedSizeName = fitResult.recommendedSize;

    final (Color? rowHighlight, Color? checkColor) = switch (fitResult.displayState) {
      FitDisplayState.match => (AppColors.fitMatchContainer, AppColors.fitMatch),
      FitDisplayState.caveats => (AppColors.fitCaveatContainer, AppColors.fitCaveat),
      _ => (null, null),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('尺寸資訊', style: textTheme.titleMedium),
        if (fitResult.displayState != FitDisplayState.unknown) ...[
          const SizedBox(height: AppSpacing.smMd),
          SizeAdvisorBanner(fitResult: fitResult),
        ],
        const SizedBox(height: AppSpacing.smMd),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columnSpacing: AppSpacing.lg,
            columns: [
              const DataColumn(label: Text('尺寸')),
              ...columnTypes.map((final type) => DataColumn(label: Text(type.label))),
            ],
            rows: sizes.map((final size) {
              final isRecommended =
                  recommendedSizeName != null && size.name == recommendedSizeName;
              return DataRow(
                color: isRecommended && rowHighlight != null
                    ? WidgetStateProperty.all(rowHighlight.withValues(alpha: 0.5))
                    : null,
                cells: [
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          size.name,
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: isRecommended ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                        if (isRecommended && checkColor != null) ...[
                          const SizedBox(width: AppSpacing.xs),
                          Icon(Icons.check_rounded, size: 14, color: checkColor),
                        ],
                      ],
                    ),
                  ),
                  ...columnTypes.map((final type) {
                    final measurements = size.measurements;
                    final value = measurements?.getValue(type);
                    return DataCell(
                      Text(
                        value != null ? value.toStringAsFixed(1) : '-',
                        style: textTheme.bodyMedium,
                      ),
                    );
                  }),
                ],
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          '* 此尺寸數據可能存在些許誤差',
          style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
