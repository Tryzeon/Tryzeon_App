import 'package:tryzeon/feature/personal/shop/domain/entities/shop_product.dart';

/// Formats a [ShopProduct] into the model-facing garment description passed to
/// the try-on prompt.
extension ShopProductTryonDetail on ShopProduct {
  String? toTryonPromptDetail() {
    final parts = <String>[];

    final productName = name.trim();
    if (productName.isNotEmpty) parts.add('Product: $productName');

    final materialText = material?.trim();
    if (materialText != null && materialText.isNotEmpty) {
      parts.add('Material: $materialText');
    }

    final fitValue = fit?.value;
    if (fitValue != null) parts.add('Fit: $fitValue');

    final elasticityValue = elasticity?.value;
    if (elasticityValue != null) parts.add('Elasticity: $elasticityValue');

    final thicknessValue = thickness?.value;
    if (thicknessValue != null) parts.add('Thickness: $thicknessValue');

    if (parts.isEmpty) return null;
    return parts.join('. ');
  }
}
