import 'package:tryzeon/core/shared/measurements/collections/size_measurements_collection.dart';
import 'package:tryzeon/core/shared/measurements/entities/size_measurements.dart';

extension SizeMeasurementsModelMapper on SizeMeasurements {
  SizeMeasurementsCollection toCollection() {
    return SizeMeasurementsCollection()
      ..height = height
      ..weight = weight
      ..shoulderWidth = shoulderWidth
      ..chest = chest
      ..waist = waist
      ..hips = hips
      ..sleeveLength = sleeveLength
      ..heightOffset = heightOffset
      ..weightOffset = weightOffset
      ..shoulderWidthOffset = shoulderWidthOffset
      ..chestOffset = chestOffset
      ..waistOffset = waistOffset
      ..hipsOffset = hipsOffset
      ..sleeveLengthOffset = sleeveLengthOffset;
  }
}

extension SizeMeasurementsCollectionMapper on SizeMeasurementsCollection {
  SizeMeasurements toModel() {
    return SizeMeasurements(
      height: height,
      weight: weight,
      shoulderWidth: shoulderWidth,
      chest: chest,
      waist: waist,
      hips: hips,
      sleeveLength: sleeveLength,
      heightOffset: heightOffset,
      weightOffset: weightOffset,
      shoulderWidthOffset: shoulderWidthOffset,
      chestOffset: chestOffset,
      waistOffset: waistOffset,
      hipsOffset: hipsOffset,
      sleeveLengthOffset: sleeveLengthOffset,
    );
  }
}
