import 'package:tryzeon/feature/common/measurement/domain/entities/measurement_unit.dart';
import 'package:tryzeon/feature/common/product_size/domain/entities/garment_measurement_type.dart';

class ParsedMeasurement {
  const ParsedMeasurement({required this.value, required this.unit});

  final double value;
  final MeasurementUnit unit;
}

class ParsedSize {
  const ParsedSize({required this.name, required this.measurements});

  final String name;
  final Map<GarmentMeasurementType, ParsedMeasurement> measurements;
}
