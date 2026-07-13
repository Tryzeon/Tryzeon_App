import 'package:auto_mappr_annotation/auto_mappr_annotation.dart';

import '../../domain/entities/measurements.dart';
import '../collections/measurements_embedded.dart';
import '../models/measurements_model.dart';
import 'measurements_mappr.auto_mappr.dart';

/// AutoMappr configuration for shared Measurements
/// Handles Measurements ↔ MeasurementsModel ↔ MeasurementsEmbedded mappings
@AutoMappr([
  MapType<MeasurementsModel, Measurements>(),
  MapType<Measurements, MeasurementsModel>(),
  MapType<MeasurementsModel, MeasurementsEmbedded>(),
  MapType<MeasurementsEmbedded, MeasurementsModel>(),
])
class MeasurementsMappr extends $MeasurementsMappr {
  const MeasurementsMappr();
}
