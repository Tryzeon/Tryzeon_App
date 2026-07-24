import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/feature/common/product_attributes/domain/entities/wardrobe_category.dart';
import 'package:tryzeon/feature/common/product_size/domain/entities/garment_category_measurements.dart';

void main() {
  group('relevantMeasurementTypesFor', () {
    test('null（未選分類或清單未載入）回傳全部欄位', () {
      expect(relevantMeasurementTypesFor(null), GarmentMeasurementType.values);
    });

    test('top 回傳上身欄位', () {
      expect(relevantMeasurementTypesFor(WardrobeCategory.top), const [
        GarmentMeasurementType.shoulderWidth,
        GarmentMeasurementType.chestCircumference,
        GarmentMeasurementType.sleeveLength,
        GarmentMeasurementType.length,
      ]);
    });

    test('bottoms 回傳下身欄位', () {
      expect(relevantMeasurementTypesFor(WardrobeCategory.bottoms), const [
        GarmentMeasurementType.waistCircumference,
        GarmentMeasurementType.hipCircumference,
        GarmentMeasurementType.length,
      ]);
    });

    test('sets 與 others 回傳全部欄位', () {
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
