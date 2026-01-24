import 'package:tryzeon/core/shared/measurements/entities/body_measurements.dart';
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

    int bestPerfectCount = -1;

    for (final size in productSizes) {
      int perfectCount = 0;
      int comparisonCount = 0;

      for (final type in MeasurementType.values) {
        final userValue = userProfile.measurements[type];
        final range = size.measurements.getRange(type);

        if (userValue != null && range != null) {
          comparisonCount++;
          // 檢查是否在區間內 (inclusive)
          if (userValue >= range.$1 && userValue <= range.$2) {
            perfectCount++;
          }
        }
      }

      if (comparisonCount > 0) {
        if (perfectCount > bestPerfectCount) {
          bestPerfectCount = perfectCount;
        }
      }
    }

    if (bestPerfectCount == -1) {
      return FitStatus.unknown;
    } else if (bestPerfectCount >= 3) {
      return FitStatus.perfect;
    } else if (bestPerfectCount == 2) {
      return FitStatus.good;
    } else {
      return FitStatus.poor;
    }
  }
}
