import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tryzeon/feature/common/body_measurements/domain/entities/body_measurement_type.dart';

part 'fit_result.freezed.dart';

enum FitDirection { tight, loose }

/// `deviation` is always positive, in centimeters; `direction` records which
/// side of the size range the user falls on.
@freezed
sealed class MeasurementCaveat with _$MeasurementCaveat {
  const factory MeasurementCaveat({
    required final BodyMeasurementType type,
    required final double deviation,
    required final FitDirection direction,
  }) = _MeasurementCaveat;
}

@freezed
sealed class FitResult with _$FitResult {
  const factory FitResult({
    final String? recommendedSize,
    final String? recommendedSizeId,
    @Default(<MeasurementCaveat>[]) final List<MeasurementCaveat> caveats,

    /// Measurements present on both sides that fell inside the size range.
    /// Only includes types compared on both sides — un-compared types are not
    /// added here, so subtitles like "{type} fits" stay accurate.
    @Default(<BodyMeasurementType>[]) final List<BodyMeasurementType> matchedTypes,
    final String? alternativeSize,
    @Default(false) final bool outOfRange,
    @Default(false) final bool noUserData,
  }) = _FitResult;
  const FitResult._();

  FitDisplayState get displayState {
    if (noUserData) return FitDisplayState.noUserData;
    if (outOfRange) return FitDisplayState.outOfRange;
    if (caveats.isNotEmpty) return FitDisplayState.caveats;
    if (recommendedSize != null) return FitDisplayState.match;
    return FitDisplayState.unknown;
  }
}

enum FitDisplayState { match, caveats, outOfRange, noUserData, unknown }
