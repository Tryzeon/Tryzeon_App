import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tryzeon/feature/common/clothing_style/domain/entities/clothing_style.dart';
import 'package:tryzeon/feature/common/product_attributes/domain/entities/product_attributes.dart';

part 'product_analysis_result.freezed.dart';

/// AI-inferred product attributes used to pre-fill the add-product form.
/// Every field is optional; the form fills only the ones that are empty.
@freezed
sealed class ProductAnalysisResult with _$ProductAnalysisResult {
  const factory ProductAnalysisResult({
    final String? name,
    @Default(<String>[]) final List<String> categoryIds,
    final ProductGender? gender,
    @Default(<ClothingStyle>[]) final List<ClothingStyle> styles,
    @Default(<ProductSeason>[]) final List<ProductSeason> seasons,
    final String? material,
    final String? fit,
    final ProductThickness? thickness,
    final ProductElasticity? elasticity,
  }) = _ProductAnalysisResult;

  const ProductAnalysisResult._();

  /// Whether the analysis populated any field that lives in the form's
  /// collapsible "advanced" section (used to auto-reveal it).
  bool get hasAdvancedFields =>
      styles.isNotEmpty ||
      seasons.isNotEmpty ||
      material != null ||
      fit != null ||
      thickness != null ||
      elasticity != null;
}
