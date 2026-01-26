import 'package:tryzeon/core/shared/measurements/collections/size_measurements_collection.dart';
import 'package:tryzeon/core/shared/measurements/entities/size_measurements.dart';

extension SizeMeasurementsModelMapper on SizeMeasurements {
  SizeMeasurementsCollection toCollection() {
    return SizeMeasurementsCollection()
      ..height = height
      ..chest = chest
      ..waist = waist
      ..hips = hips
      ..shoulder = shoulder
      ..sleeve = sleeve
      ..heightOffset = heightOffset
      ..chestOffset = chestOffset
      ..waistOffset = waistOffset
      ..hipsOffset = hipsOffset
      ..shoulderOffset = shoulderOffset
      ..sleeveOffset = sleeveOffset;
  }
}

extension SizeMeasurementsCollectionMapper on SizeMeasurementsCollection {
  SizeMeasurements toModel() {
    return SizeMeasurements(
      height: height,
      chest: chest,
      waist: waist,
      hips: hips,
      shoulder: shoulder,
      sleeve: sleeve,
      heightOffset: heightOffset,
      chestOffset: chestOffset,
      waistOffset: waistOffset,
      hipsOffset: hipsOffset,
      shoulderOffset: shoulderOffset,
      sleeveOffset: sleeveOffset,
    );
  }
}
