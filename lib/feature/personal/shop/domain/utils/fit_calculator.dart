import 'package:tryzeon/core/domain/entities/body_measurements.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/user_profile.dart';
import 'package:tryzeon/feature/personal/shop/domain/enums/fit_status.dart';
import 'package:tryzeon/feature/store/products/domain/entities/product.dart';

class FitCalculator {
  static FitStatus calculate({
    required final UserProfile? userProfile,
    required final List<ProductSize>? productSizes,
  }) {
    if (userProfile == null || productSizes == null) {
      return FitStatus.unknown;
    }

    double? bestDiff;

    for (final size in productSizes) {
      double totalDiff = 0;
      int comparisonCount = 0;

      for (final type in MeasurementType.values) {
        final userValue = userProfile.measurements[type];
        final sizeValue = size.measurements[type];

        if (userValue != null && sizeValue != null) {
          totalDiff += (userValue - sizeValue).abs();
          comparisonCount++;
        }
      }

      if (comparisonCount > 0) {
        if (bestDiff == null || totalDiff < bestDiff) {
          bestDiff = totalDiff;
        }
      }
    }

    if (bestDiff == null) {
      return FitStatus.unknown;
    } else if (bestDiff <= 5) {
      return FitStatus.perfect;
    } else if (bestDiff <= 10) {
      return FitStatus.good;
    } else {
      return FitStatus.poor;
    }
  }
}
