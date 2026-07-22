import 'package:tryzeon/feature/common/measurements/domain/entities/measurements.dart';

/// Total number of core measurement fields the user can fill.
int get totalMeasurementFields => MeasurementType.values.length;

/// Counts how many of the six core measurement fields have a non-null value.
int countFilledMeasurements(final Measurements? measurements) {
  if (measurements == null) return 0;
  var count = 0;
  for (final type in MeasurementType.values) {
    if (measurements.getValue(type) != null) count++;
  }
  return count;
}
