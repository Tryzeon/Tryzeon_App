import 'package:auto_mappr_annotation/auto_mappr_annotation.dart';

import '../../domain/entities/garment_measurements.dart';
import '../collections/garment_measurements_embedded.dart';
import '../models/garment_measurements_model.dart';
import 'garment_measurements_mappr.auto_mappr.dart';

@AutoMappr([
  MapType<GarmentMeasurementsModel, GarmentMeasurements>(),
  MapType<GarmentMeasurements, GarmentMeasurementsModel>(),
  MapType<GarmentMeasurementsModel, GarmentMeasurementsEmbedded>(),
  MapType<GarmentMeasurementsEmbedded, GarmentMeasurementsModel>(),
])
class GarmentMeasurementsMappr extends $GarmentMeasurementsMappr {
  const GarmentMeasurementsMappr();
}
