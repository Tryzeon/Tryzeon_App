import 'package:tryzeon/feature/common/measurements/domain/entities/measurements.dart';
import 'package:tryzeon/feature/common/product_size/domain/entities/product_size.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/user_profile.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/fit_result.dart';

/// Scores every product size by total deviation when user measurements fall
/// outside the size range, and recommends the closest one.
class FitCalculator {
  FitCalculator._();

  /// Any single measurement beyond this deviation triggers outOfRange.
  static const double _outOfRangeSingleThreshold = 5.0;

  /// Total deviation beyond this value triggers outOfRange.
  static const double _outOfRangeTotalThreshold = 8.0;

  /// The second-best size is only suggested when its total distance is within
  /// this value of the best size.
  static const double _alternativeThreshold = 2.0;

  static FitResult calculate({
    required final UserProfile? userProfile,
    required final List<ProductSize>? productSizes,
  }) {
    final userMeasurements = userProfile?.measurements;
    if (userMeasurements == null) {
      return const FitResult(noUserData: true);
    }

    final hasAnyMeasurement = MeasurementType.values.any(
      (final t) => userMeasurements.getValue(t) != null,
    );
    if (!hasAnyMeasurement) {
      return const FitResult(noUserData: true);
    }

    if (productSizes == null || productSizes.isEmpty) {
      return const FitResult();
    }

    final scoredSizes = <_ScoredSize>[];
    for (final size in productSizes) {
      final scored = _scoreSize(size, userMeasurements);
      if (scored != null) scoredSizes.add(scored);
    }

    if (scoredSizes.isEmpty) {
      return const FitResult();
    }

    scoredSizes.sort((final a, final b) => a.totalDistance.compareTo(b.totalDistance));

    final validSizes = scoredSizes
        .where(
          (final s) =>
              s.worstDistance <= _outOfRangeSingleThreshold &&
              s.totalDistance <= _outOfRangeTotalThreshold,
        )
        .toList();

    if (validSizes.isEmpty) {
      return const FitResult(outOfRange: true);
    }

    final best = validSizes.first;

    String? alternativeSize;
    if (validSizes.length > 1) {
      final second = validSizes[1];
      if (second.totalDistance - best.totalDistance < _alternativeThreshold) {
        alternativeSize = second.size.name;
      }
    }

    return FitResult(
      recommendedSize: best.size.name,
      caveats: best.caveats,
      matchedTypes: best.matchedTypes,
      alternativeSize: alternativeSize,
    );
  }

  static _ScoredSize? _scoreSize(
    final ProductSize size,
    final Measurements userMeasurements,
  ) {
    final sizeMeasurements = size.measurements;
    if (sizeMeasurements == null) return null;

    double totalDistance = 0;
    double worstDistance = 0;
    int comparisonCount = 0;
    final caveats = <MeasurementCaveat>[];
    final matchedTypes = <MeasurementType>[];

    for (final type in MeasurementType.values) {
      final userValue = userMeasurements.getValue(type);
      final range = sizeMeasurements.getRange(type);
      if (userValue == null || range == null) continue;

      comparisonCount++;
      double distance = 0;
      FitDirection? direction;

      if (userValue >= range.$1 && userValue <= range.$2) {
        matchedTypes.add(type);
      } else if (userValue > range.$2) {
        distance = userValue - range.$2;
        direction = FitDirection.tight;
      } else {
        distance = range.$1 - userValue;
        direction = FitDirection.loose;
      }

      if (distance > 0) {
        caveats.add(
          MeasurementCaveat(type: type, deviation: distance, direction: direction!),
        );
      }
      totalDistance += distance;
      if (distance > worstDistance) worstDistance = distance;
    }

    if (comparisonCount == 0) return null;

    return _ScoredSize(
      size: size,
      totalDistance: totalDistance,
      worstDistance: worstDistance,
      caveats: caveats,
      matchedTypes: matchedTypes,
    );
  }
}

class _ScoredSize {
  const _ScoredSize({
    required this.size,
    required this.totalDistance,
    required this.worstDistance,
    required this.caveats,
    required this.matchedTypes,
  });

  final ProductSize size;
  final double totalDistance;
  final double worstDistance;
  final List<MeasurementCaveat> caveats;
  final List<MeasurementType> matchedTypes;
}
