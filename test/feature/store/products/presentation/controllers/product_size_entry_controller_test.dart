import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/feature/common/measurements/domain/entities/measurement_unit.dart';
import 'package:tryzeon/feature/common/product_size/domain/entities/garment_category_measurements.dart';
import 'package:tryzeon/feature/store/products/domain/value_objects/size_item.dart';
import 'package:tryzeon/feature/store/products/presentation/controllers/product_size_entry_controller.dart';

void main() {
  group('matchKey', () {
    test('不做別名轉換：XXL 與 2XL 是不同的尺寸', () {
      expect(
        ProductSizeEntryController(label: 'XXL').matchKey,
        isNot(ProductSizeEntryController(label: '2XL').matchKey),
      );
    });

    test('大小寫不同視為同一個尺寸', () {
      expect(
        ProductSizeEntryController(label: 'm').matchKey,
        ProductSizeEntryController(label: 'M').matchKey,
      );
    });

    test('自訂尺碼只做大小寫正規化', () {
      expect(ProductSizeEntryController(label: 'us 10').matchKey, 'US 10');
    });
  });

  group('toSizeItem', () {
    test('沒有 id 時產生 NewSizeItem，名稱用 label', () {
      final entry = ProductSizeEntryController(label: '4XL');
      entry.measurementControllers[GarmentMeasurementType.chestCircumference]!.text =
          '100';
      final item = entry.toSizeItem(
        unit: MeasurementUnit.centimeter,
        visibleTypes: const [GarmentMeasurementType.chestCircumference],
      );
      expect(item, isA<NewSizeItem>());
      expect((item as NewSizeItem).name, '4XL');
      expect(item.measurements?.getValue(GarmentMeasurementType.chestCircumference), 100);
    });

    test('有 id 時產生 ExistingSizeItem', () {
      final entry = ProductSizeEntryController(label: 'M', id: 'size-1');
      final item = entry.toSizeItem(
        unit: MeasurementUnit.centimeter,
        visibleTypes: const [GarmentMeasurementType.chestCircumference],
      );
      expect(item, isA<ExistingSizeItem>());
      expect((item as ExistingSizeItem).id, 'size-1');
    });
  });
}
