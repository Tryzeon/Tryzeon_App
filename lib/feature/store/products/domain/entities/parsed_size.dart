import 'package:tryzeon/feature/common/measurements/entities/measurement_type.dart';
import 'package:tryzeon/feature/common/measurements/entities/measurement_unit.dart';

class ParsedMeasurement {
  const ParsedMeasurement({
    required this.value,
    required this.unit,
    this.offset,
  });

  final double value;
  final MeasurementUnit unit;
  final double? offset;
}

class ParsedSize {
  const ParsedSize({required this.name, required this.measurements});

  final String name;
  final Map<MeasurementType, ParsedMeasurement> measurements;
}
