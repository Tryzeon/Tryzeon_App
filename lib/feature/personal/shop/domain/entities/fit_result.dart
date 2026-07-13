import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tryzeon/feature/common/measurements/domain/entities/measurement_type.dart';

part 'fit_result.freezed.dart';

enum FitDirection { tight, loose }

/// `deviation` is always positive, in centimeters; `direction` records which
/// side of the size range the user falls on.
@freezed
sealed class MeasurementCaveat with _$MeasurementCaveat {
  const factory MeasurementCaveat({
    required final MeasurementType type,
    required final double deviation,
    required final FitDirection direction,
  }) = _MeasurementCaveat;
}

@freezed
sealed class FitResult with _$FitResult {
  const factory FitResult({
    final String? recommendedSize,
    @Default(<MeasurementCaveat>[]) final List<MeasurementCaveat> caveats,

    /// Measurements present on both sides that fell inside the size range.
    /// Only includes types compared on both sides — un-compared types are not
    /// added here, so subtitles like "{type} fits" stay accurate.
    @Default(<MeasurementType>[]) final List<MeasurementType> matchedTypes,
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
