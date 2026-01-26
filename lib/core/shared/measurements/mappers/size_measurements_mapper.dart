import 'package:tryzeon/core/shared/measurements/collections/size_measurements_collection.dart';
import 'package:tryzeon/core/shared/measurements/entities/size_measurements.dart';

extension SizeMeasurementsModelMapper on SizeMeasurements {
  SizeMeasurementsCollection toCollection() {
    return SizeMeasurementsCollection()
      ..height = height
      ..chest = chest
      ..waist = waist
      ..hips = hips
      ..shoulderWidth = shoulderWidth
      ..sleeveLength = sleeveLength
      ..heightOffset = heightOffset
      ..chestOffset = chestOffset
      ..waistOffset = waistOffset
      ..hipsOffset = hipsOffset
      ..shoulderWidthOffset = shoulderWidthOffset
      ..sleeveLengthOffset = sleeveLengthOffset;
  }
}

extension SizeMeasurementsCollectionMapper on SizeMeasurementsCollection {
  SizeMeasurements toModel() {
    return SizeMeasurements(
      height: height,
      chest: chest,
      waist: waist,
      hips: hips,
      shoulderWidth: shoulderWidth,
      sleeveLength: sleeveLength,
      heightOffset: heightOffset,
      chestOffset: chestOffset,
      waistOffset: waistOffset,
      hipsOffset: hipsOffset,
      shoulderWidthOffset: shoulderWidthOffset,
      sleeveLengthOffset: sleeveLengthOffset,
    );
  }
}
