import 'package:tryzeon/feature/common/product_size/domain/entities/product_size.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/user_profile.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/fit_result.dart';

/// Size-fit recommendation.
///
/// PLACEHOLDER: the previous range-based implementation was removed together
/// with the per-size measurement offset. It compared the shopper's *body*
/// measurements directly against the garment's *flat* measurements, which is
/// not a valid fit signal (a garment that fits is larger than the body by an
/// intended amount of ease that depends on cut and stretch).
///
/// The vocabulary half of the problem is now solved: `GarmentFitDimension`
/// (`garment_fit_dimension.dart`) states which garment dimensions map onto a
/// body dimension and which are display-only, so lengths and body height can
/// no longer leak into a fit score. What remains is the ease model itself —
/// deriving tolerance from the product's `fit` silhouette, `elasticity`, and
/// garment category — which is intentionally deferred because it needs real
/// calibration data rather than invented constants.
///
/// Until then this returns an empty [FitResult] (`FitDisplayState.unknown`),
/// which hides the size-advisor banner and the recommended-size highlight.
class FitCalculator {
  FitCalculator._();

  static FitResult calculate({
    required final UserProfile? userProfile,
    required final List<ProductSize>? productSizes,
  }) {
    return const FitResult();
  }
}
