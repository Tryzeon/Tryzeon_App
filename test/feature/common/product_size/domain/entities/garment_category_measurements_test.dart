import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/feature/common/product_attributes/domain/entities/wardrobe_category.dart';
import 'package:tryzeon/feature/common/product_size/domain/entities/garment_category_measurements.dart';

void main() {
  group('relevantMeasurementTypesFor', () {
    test('null (no category, or the list has not loaded) returns every field', () {
      expect(relevantMeasurementTypesFor(null), GarmentMeasurementType.values);
    });

    test('top returns the upper-body fields', () {
      expect(relevantMeasurementTypesFor(WardrobeCategory.top), const [
        GarmentMeasurementType.shoulderWidth,
        GarmentMeasurementType.chestCircumference,
        GarmentMeasurementType.sleeveLength,
        GarmentMeasurementType.length,
      ]);
    });

    test('bottoms returns the lower-body fields', () {
      expect(relevantMeasurementTypesFor(WardrobeCategory.bottoms), const [
        GarmentMeasurementType.waistCircumference,
        GarmentMeasurementType.hipCircumference,
        GarmentMeasurementType.thighCircumference,
        GarmentMeasurementType.length,
      ]);
    });

    test('sets and others return every field', () {
      expect(
        relevantMeasurementTypesFor(WardrobeCategory.sets),
        GarmentMeasurementType.values,
      );
      expect(
        relevantMeasurementTypesFor(WardrobeCategory.others),
        GarmentMeasurementType.values,
      );
    });
  });
}
