import 'package:auto_mappr_annotation/auto_mappr_annotation.dart';

import '../../domain/entities/body_measurements.dart';
import '../collections/body_measurements_embedded.dart';
import '../models/body_measurements_model.dart';
import 'body_measurements_mappr.auto_mappr.dart';

@AutoMappr([
  MapType<BodyMeasurementsModel, BodyMeasurements>(whenSourceIsNull: BodyMeasurements()),
  MapType<BodyMeasurements, BodyMeasurementsModel>(),
  MapType<BodyMeasurementsModel, BodyMeasurementsEmbedded>(),
  MapType<BodyMeasurementsEmbedded, BodyMeasurementsModel>(),
])
class BodyMeasurementsMappr extends $BodyMeasurementsMappr {
  const BodyMeasurementsMappr();
}
