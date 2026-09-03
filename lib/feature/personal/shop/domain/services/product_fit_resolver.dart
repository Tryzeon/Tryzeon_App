import 'package:tryzeon/feature/common/body_measurements/domain/entities/body_measurements.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/fit_result.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_product.dart';
import 'package:tryzeon/feature/personal/shop/domain/services/fit_calculator.dart';

/// Answers "how does this product fit *this* shopper" for a catalog whose
/// shopper is already known.
class ProductFitResolver {
  const ProductFitResolver({required this.body});

  final BodyMeasurements? body;

  FitResult resolve(final ShopProduct product) => FitCalculator.calculate(
    body: body,
    productSizes: product.sizes,
    fit: product.fit,
    elasticity: product.elasticity,
  );
}
