import 'package:tryzeon/feature/common/body_measurements/domain/entities/body_measurement_type.dart';
import 'package:tryzeon/feature/common/product_attributes/domain/entities/product_attributes.dart';

/// The ease model for [FitCalculator]: how much larger than the body a garment
/// dimension is expected to be for a given silhouette and fabric.
///
/// A garment that fits is not equal to the body — it is larger by an intended
/// amount of *ease*. How much depends on the cut (`ProductFit`) and, for
/// circumferences, on how much the fabric stretches (`ProductElasticity`). This
/// class is the single home for those numbers, deliberately isolated so the
/// whole model can be re-calibrated against real try-on feedback without
/// touching the comparison algorithm in [FitCalculator].
///
/// The bands come from standard patternmaking ease allowances (close-fitting
/// through very-loose-fitting) mapped onto this app's four `ProductFit` values,
/// not from measured data — treat every constant here as a starting estimate.
///
/// All values are centimeters. A band `(min, max)` means: for the garment to
/// count as this fit, its measurement should satisfy
/// `body + min <= garment <= body + max`.
class EaseBand {
  const EaseBand(this.min, this.max);

  final double min;
  final double max;

  /// The ideal ease for this silhouette — used to rank sizes that all fit.
  double get center => (min + max) / 2;

  EaseBand _shiftMin(final double delta) => EaseBand(min + delta, max);
}

class EaseTable {
  EaseTable._();

  /// Silhouette assumed when the store did not tag the product's fit — the
  /// neutral, most common cut.
  static const ProductFit _defaultFit = ProductFit.regular;

  /// Fabric assumed when elasticity is untagged — no stretch, so ease must be
  /// fully positive.
  static const ProductElasticity _defaultElasticity = ProductElasticity.none;

  /// The dimensions on which fabric stretch changes the fit. Seam dimensions
  /// like shoulder width do not accommodate stretch the way a circumference
  /// wrapping the body does, so elasticity is not applied to them.
  static const Set<BodyMeasurementType> _circumferences = {
    BodyMeasurementType.chest,
    BodyMeasurementType.waist,
    BodyMeasurementType.hips,
    BodyMeasurementType.thigh,
  };

  /// Base ease bands, before any elasticity adjustment, keyed by silhouette and
  /// body dimension. Circumference ease widens from slim to oversize; shoulder
  /// width stays near the body with a small tolerance. Waist, hips, and thigh
  /// are calibrated to trouser (bottoms) ease, distinct from the looser chest
  /// allowance used for tops.
  static const Map<ProductFit, Map<BodyMeasurementType, EaseBand>> _bands = {
    ProductFit.slim: {
      BodyMeasurementType.shoulder: EaseBand(-1, 2),
      BodyMeasurementType.chest: EaseBand(4, 11),
      BodyMeasurementType.waist: EaseBand(0, 3),
      BodyMeasurementType.hips: EaseBand(2, 6),
      BodyMeasurementType.thigh: EaseBand(1, 4),
    },
    ProductFit.regular: {
      BodyMeasurementType.shoulder: EaseBand(0, 3),
      BodyMeasurementType.chest: EaseBand(8, 15),
      BodyMeasurementType.waist: EaseBand(1, 4),
      BodyMeasurementType.hips: EaseBand(4, 9),
      BodyMeasurementType.thigh: EaseBand(3, 7),
    },
    ProductFit.loose: {
      BodyMeasurementType.shoulder: EaseBand(1, 5),
      BodyMeasurementType.chest: EaseBand(13, 24),
      BodyMeasurementType.waist: EaseBand(3, 8),
      BodyMeasurementType.hips: EaseBand(7, 14),
      BodyMeasurementType.thigh: EaseBand(6, 12),
    },
    ProductFit.oversize: {
      BodyMeasurementType.shoulder: EaseBand(2, 8),
      BodyMeasurementType.chest: EaseBand(20, 40),
      BodyMeasurementType.waist: EaseBand(6, 14),
      BodyMeasurementType.hips: EaseBand(12, 24),
      BodyMeasurementType.thigh: EaseBand(10, 20),
    },
  };

  /// How much a stretchy fabric lowers the *minimum* acceptable ease. Stretch
  /// lets a garment be tighter than the body and still fit (negative ease on
  /// knitwear), so it opens the band downward; it never changes the maximum,
  /// because a stretchy loose garment is still loose.
  static const Map<ProductElasticity, double> _elasticityMinShift = {
    ProductElasticity.none: 0,
    ProductElasticity.low: -2,
    ProductElasticity.medium: -5,
    ProductElasticity.high: -9,
  };

  /// Relative importance of each dimension when ranking sizes and choosing which
  /// mismatch to report. Circumferences drive fit; shoulder width is the least
  /// decisive of the comparable dimensions.
  static const Map<BodyMeasurementType, double> _weights = {
    BodyMeasurementType.chest: 1,
    BodyMeasurementType.waist: 1,
    BodyMeasurementType.hips: 1,
    BodyMeasurementType.shoulder: 0.8,
    BodyMeasurementType.thigh: 0.8,
  };

  /// The largest single-dimension miss (cm) still worth recommending with a
  /// caveat. Beyond this the product simply does not carry the shopper's size.
  static const double maxRecommendableDeviation = 6;

  /// The elasticity-adjusted ease band for a dimension, or `null` if the
  /// dimension carries no fit signal (only the five comparable body dimensions
  /// have bands; `height` never does).
  static EaseBand? bandFor(
    final BodyMeasurementType type,
    final ProductFit? fit,
    final ProductElasticity? elasticity,
  ) {
    final base = _bands[fit ?? _defaultFit]?[type];
    if (base == null) return null;
    if (!_circumferences.contains(type)) return base;
    final shift = _elasticityMinShift[elasticity ?? _defaultElasticity] ?? 0;
    return base._shiftMin(shift);
  }

  static double weightFor(final BodyMeasurementType type) => _weights[type] ?? 1;
}
