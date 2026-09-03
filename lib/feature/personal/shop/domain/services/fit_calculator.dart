import 'package:tryzeon/feature/common/body_measurements/domain/entities/body_measurements.dart';
import 'package:tryzeon/feature/common/product_attributes/domain/entities/product_attributes.dart';
import 'package:tryzeon/feature/common/product_size/domain/entities/product_size.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/fit_result.dart';
import 'package:tryzeon/feature/personal/shop/domain/services/ease_table.dart';
import 'package:tryzeon/feature/personal/shop/domain/services/garment_fit_dimension.dart';

/// For every published size it measures each comparable dimension's *ease*
/// (garment minus body) against the expected band and decides whether the size
/// fits, runs tight, or runs loose. A garment's length and the shopper's height
/// carry no fit signal and are never read here.
///
/// Dimensions absent on either side are skipped rather than guessed, so a size
/// judged on chest alone says so ("chest fits") instead of implying a full-body
/// match.
class FitCalculator {
  FitCalculator._();

  static FitResult calculate({
    required final BodyMeasurements? body,
    required final List<ProductSize>? productSizes,
    required final ProductFit? fit,
    required final ProductElasticity? elasticity,
  }) {
    final userDimensions = fitComparableGarmentTypes
        .map((final g) => g.comparableBodyType!)
        .where((final b) => body?.getValue(b) != null)
        .toList();
    if (userDimensions.isEmpty) return const FitResult(noUserData: true);

    final sizes = productSizes ?? const <ProductSize>[];
    final evaluated = sizes
        .map((final size) => _evaluate(size, body!, userDimensions, fit, elasticity))
        .where((final e) => e.dimensions.isNotEmpty)
        .toList();

    // The shopper has data, but no published size overlaps it — nothing to
    // advise on, so the banner stays hidden.
    if (evaluated.isEmpty) return const FitResult();

    final cleanMatches = evaluated.where((final e) => e.fitsCleanly).toList();
    if (cleanMatches.isNotEmpty) {
      cleanMatches.sort((final a, final b) => a.centerScore.compareTo(b.centerScore));
      final best = cleanMatches.first;
      final alternative = cleanMatches.length > 1 ? cleanMatches[1] : null;
      return FitResult(
        recommendedSize: best.size.name,
        tryonSizeId: best.size.id,
        matchedTypes: best.matchedTypes,
        alternativeSize: alternative?.size.name,
      );
    }

    // The cap is applied before ranking, not after: the lowest total miss can
    // still be one nobody would wear (a single huge miss beats several small
    // ones on a sum), and rejecting it afterwards would discard the sizes that
    // were actually wearable.
    evaluated.sort((final a, final b) => a.deviationScore.compareTo(b.deviationScore));
    final recommendable = evaluated
        .where((final e) => e.maxDeviation <= EaseTable.maxRecommendableDeviation)
        .toList();
    // The closest size still goes to the try-on: the banner says there is no
    // size for them, and the render is what shows them why.
    if (recommendable.isEmpty) {
      return FitResult(outOfRange: true, tryonSizeId: evaluated.first.size.id);
    }

    final best = recommendable.first;
    return FitResult(
      recommendedSize: best.size.name,
      tryonSizeId: best.size.id,
      caveats: best.caveats,
      matchedTypes: best.matchedTypes,
    );
  }

  static _SizeFit _evaluate(
    final ProductSize size,
    final BodyMeasurements body,
    final List<BodyMeasurementType> userDimensions,
    final ProductFit? fit,
    final ProductElasticity? elasticity,
  ) {
    final dimensions = <_DimensionFit>[];
    for (final garmentType in fitComparableGarmentTypes) {
      final bodyType = garmentType.comparableBodyType!;
      if (!userDimensions.contains(bodyType)) continue;

      final garmentValue = size.measurements?.getValue(garmentType);
      final bodyValue = body.getValue(bodyType);
      if (garmentValue == null || bodyValue == null) continue;

      final band = EaseTable.bandFor(bodyType, fit, elasticity);
      if (band == null) continue;

      dimensions.add(
        _DimensionFit(type: bodyType, ease: garmentValue - bodyValue, band: band),
      );
    }
    return _SizeFit(size: size, dimensions: dimensions);
  }
}

class _DimensionFit {
  _DimensionFit({required this.type, required this.ease, required this.band});

  final BodyMeasurementType type;

  /// Garment measurement minus body measurement, in centimeters.
  final double ease;
  final EaseBand band;

  bool get isTight => ease < band.min;
  bool get isLoose => ease > band.max;
  bool get inRange => !isTight && !isLoose;

  double get deviation {
    if (isTight) return band.min - ease;
    if (isLoose) return ease - band.max;
    return 0;
  }

  double get weight => EaseTable.weightFor(type);

  MeasurementCaveat get caveat => MeasurementCaveat(
    type: type,
    deviation: deviation,
    direction: isTight ? FitDirection.tight : FitDirection.loose,
  );
}

class _SizeFit {
  _SizeFit({required this.size, required this.dimensions}) {
    centerScore = dimensions.fold(
      0,
      (final sum, final d) => sum + (d.ease - d.band.center).abs() * d.weight,
    );
  }

  final ProductSize size;
  final List<_DimensionFit> dimensions;

  bool get fitsCleanly => dimensions.every((final d) => d.inRange);

  /// Weighted distance from the ideal ease. Ranks sizes that all fit cleanly.
  double centerScore = 0;

  /// Weighted sum of out-of-range distances. Ranks sizes when none fit cleanly.
  double get deviationScore =>
      dimensions.fold(0, (final sum, final d) => sum + d.deviation * d.weight);

  double get maxDeviation =>
      dimensions.fold(0, (final max, final d) => d.deviation > max ? d.deviation : max);

  List<BodyMeasurementType> get matchedTypes =>
      dimensions.where((final d) => d.inRange).map((final d) => d.type).toList();

  List<MeasurementCaveat> get caveats =>
      dimensions.where((final d) => !d.inRange).map((final d) => d.caveat).toList();
}
