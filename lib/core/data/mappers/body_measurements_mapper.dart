import 'package:tryzeon/core/domain/entities/body_measurements.dart';

import '../collections/body_measurements_collection.dart';

extension BodyMeasurementsModelMapper on BodyMeasurements {
  BodyMeasurementsCollection toCollection() {
    return BodyMeasurementsCollection()
      ..height = height
      ..weight = weight
      ..shoulderWidth = shoulderWidth
      ..chest = chest
      ..waist = waist
      ..hips = hips
      ..sleeveLength = sleeveLength;
  }
}

extension BodyMeasurementsCollectionMapper on BodyMeasurementsCollection {
  BodyMeasurements toModel() {
    return BodyMeasurements(
      height: height,
      weight: weight,
      shoulderWidth: shoulderWidth,
      chest: chest,
      waist: waist,
      hips: hips,
      sleeveLength: sleeveLength,
    );
  }
}
