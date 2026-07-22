import 'package:tryzeon/feature/common/measurements/domain/entities/measurement_type.dart';
import 'package:tryzeon/feature/common/measurements/domain/entities/measurement_unit.dart';

class ParsedMeasurement {
  const ParsedMeasurement({required this.value, required this.unit});

  final double value;
  final MeasurementUnit unit;
}

class ParsedSize {
  const ParsedSize({required this.name, required this.measurements});

  final String name;
  final Map<MeasurementType, ParsedMeasurement> measurements;
}
