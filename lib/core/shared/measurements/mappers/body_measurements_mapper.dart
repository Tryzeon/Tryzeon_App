import 'package:tryzeon/core/shared/measurements/entities/body_measurements.dart';

import '../collections/body_measurements_collection.dart';

extension BodyMeasurementsModelMapper on BodyMeasurements {
  BodyMeasurementsCollection toCollection() {
    return BodyMeasurementsCollection()
      ..height = height
      ..chest = chest
      ..waist = waist
      ..hips = hips
      ..shoulder = shoulder
      ..sleeve = sleeve;
  }
}

extension BodyMeasurementsCollectionMapper on BodyMeasurementsCollection {
  BodyMeasurements toModel() {
    return BodyMeasurements(
      height: height,
      chest: chest,
      waist: waist,
      hips: hips,
      shoulder: shoulder,
      sleeve: sleeve,
    );
  }
}
