import 'package:tryzeon/feature/common/body_measurements/domain/entities/body_measurements.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/fit_result.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_product.dart';
import 'package:tryzeon/feature/personal/shop/domain/services/fit_calculator.dart';

/// Answers "how does this product fit *this* shopper" for a catalog whose
/// shopper is already known.
///
/// [FitCalculator] takes a garment's attributes and a body; the shopper's body
/// is the same for every product on screen. Holding it still here is what lets
/// the product grid, the store page, and the product detail page answer
/// identically, and keeps the grid from re-reading the profile for every card
/// on every scroll frame.
///
/// Deliberately a plain value rather than a provider: the policy is pure and
/// testable on its own, and the wiring that supplies [body] stays in the
/// provider layer where it belongs.
class ProductFitResolver {
  const ProductFitResolver({required this.body});

  /// The shopper's measurements, or `null` when they have recorded none.
  final BodyMeasurements? body;

  FitResult resolve(final ShopProduct product) => FitCalculator.calculate(
    body: body,
    productSizes: product.sizes,
    fit: product.fit,
    elasticity: product.elasticity,
  );
}
