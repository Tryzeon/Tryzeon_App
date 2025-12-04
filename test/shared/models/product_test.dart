import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/shared/models/body_measurements.dart';
import 'package:tryzeon/shared/models/product.dart';

void main() {
  group('Product', () {
    test('fromJson parses valid JSON correctly', () {
      final json = {
        'id': 'prod_123',
        'store_id': 'store_456',
        'name': 'Test Product',
        'type': ['Shirt', 'Top'],
        'price': 1000,
        'image_path': 'path/to/image.jpg',
        'purchase_link': 'https://example.com',
        'created_at': '2023-01-01T12:00:00.000Z',
        'updated_at': '2023-01-02T12:00:00.000Z',
        'tryon_count': 10,
        'purchase_click_count': 5,
        'store_profile': {'name': 'Test Store'},
        'product_sizes': [
          {'id': 'size_1', 'product_id': 'prod_123', 'name': 'M', 'height': 175.0},
        ],
      };

      final product = Product.fromJson(json);

      expect(product.id, 'prod_123');
      expect(product.storeId, 'store_456');
      expect(product.name, 'Test Product');
      expect(product.types, {'Shirt', 'Top'});
      expect(product.price, 1000);
      expect(product.imagePath, 'path/to/image.jpg');
      expect(product.purchaseLink, 'https://example.com');
      expect(product.createdAt, DateTime.utc(2023, 1, 1, 12, 0, 0));
      expect(product.updatedAt, DateTime.utc(2023, 1, 2, 12, 0, 0));
      expect(product.tryonCount, 10);
      expect(product.purchaseClickCount, 5);
      expect(product.storeName, 'Test Store');
      expect(product.sizes?.length, 1);
      expect(product.sizes?.first.name, 'M');
    });

    test('toJson converts object to valid JSON', () {
      final product = Product(
        id: 'prod_123',
        storeId: 'store_456',
        name: 'Test Product',
        types: {'Shirt', 'Top'},
        price: 1000,
        imagePath: 'path/to/image.jpg',
        purchaseLink: 'https://example.com',
        createdAt: DateTime.utc(2023, 1, 1, 12, 0, 0),
        updatedAt: DateTime.utc(2023, 1, 2, 12, 0, 0),
        tryonCount: 10,
        purchaseClickCount: 5,
        storeName: 'Test Store',
      );

      final json = product.toJson();

      expect(json['id'], 'prod_123');
      expect(json['store_id'], 'store_456');
      expect(json['name'], 'Test Product');
      expect(json['type'], ['Shirt', 'Top']);
      expect(json['price'], 1000);
      expect(json['image_path'], 'path/to/image.jpg');
      expect(json['purchase_link'], 'https://example.com');
      expect(json['created_at'], isNotNull);
      expect(json['updated_at'], isNotNull);
      expect(json['tryon_count'], 10);
      expect(json['purchase_click_count'], 5);
    });

    test('getDirtyFields detects changes correctly', () {
      final original = Product(
        storeId: 'store_1',
        name: 'Original Name',
        types: {'A', 'B'},
        price: 100,
        imagePath: 'img.jpg',
        purchaseLink: 'link.com',
      );

      // Case 1: No changes
      final same = Product(
        storeId: 'store_1',
        name: 'Original Name',
        types: {'B', 'A'}, // Different order, same content
        price: 100,
        imagePath: 'img.jpg',
        purchaseLink: 'link.com',
      );
      expect(original.getDirtyFields(same), isEmpty);

      // Case 2: Changes
      final changed = Product(
        storeId: 'store_1',
        name: 'New Name',
        types: {'A', 'C'},
        price: 200,
        imagePath: 'new_img.jpg',
        purchaseLink: 'new_link.com',
      );
      final dirty = original.getDirtyFields(changed);

      expect(dirty['name'], 'New Name');
      expect(dirty['type'], containsAll(['A', 'C']));
      expect(dirty['price'], 200);
      expect(dirty['image_path'], 'new_img.jpg');
      expect(dirty['purchase_link'], 'new_link.com');
    });

    test('copyWith creates new instance with updated values', () {
      final original = Product(
        storeId: 'store_1',
        name: 'Original Name',
        types: {'A'},
        price: 100,
        imagePath: 'img.jpg',
      );

      final copy = original.copyWith(
        name: 'New Name',
        price: 200,
      );

      expect(copy.storeId, original.storeId);
      expect(copy.name, 'New Name');
      expect(copy.price, 200);
      expect(copy.types, original.types);
      expect(copy.imagePath, original.imagePath);

      final copyTypes = original.copyWith(types: {'B'});
      expect(copyTypes.types, {'B'});
    });
  });

  group('ProductSize', () {
    test('fromJson parses valid JSON correctly', () {
      final json = {
        'id': 'size_1',
        'product_id': 'prod_123',
        'name': 'L',
        'height': 180.0,
        'weight': 75.0,
      };

      final size = ProductSize.fromJson(json);

      expect(size.id, 'size_1');
      expect(size.productId, 'prod_123');
      expect(size.name, 'L');
      expect(size.measurements.height, 180.0);
      expect(size.measurements.weight, 75.0);
    });

    test('toJson converts object to valid JSON', () {
      final size = ProductSize(
        id: 'size_1',
        productId: 'prod_123',
        name: 'L',
        measurements: const BodyMeasurements(height: 180.0, weight: 75.0),
      );

      final json = size.toJson();

      expect(json['id'], 'size_1');
      expect(json['product_id'], 'prod_123');
      expect(json['name'], 'L');
      expect(json['height'], 180.0);
      expect(json['weight'], 75.0);
    });

    test('copyWith creates new instance with updated values', () {
      final original = ProductSize(
        id: 's1',
        name: 'M',
        measurements: const BodyMeasurements(height: 170),
      );

      final copy = original.copyWith(name: 'L');
      expect(copy.id, original.id);
      expect(copy.name, 'L');
      expect(copy.measurements, original.measurements);

      final copyMeasure = original.copyWith(
        measurements: const BodyMeasurements(height: 180),
      );
      expect(copyMeasure.measurements.height, 180);
    });

    test('getDirtyFields detects changes correctly', () {
      final original = ProductSize(
        id: 's1',
        name: 'M',
        measurements: const BodyMeasurements(height: 170, weight: 60),
      );

      // Case 1: No changes
      final same = ProductSize(
        id: 's1',
        name: 'M',
        measurements: const BodyMeasurements(height: 170, weight: 60),
      );
      expect(original.getDirtyFields(same), isEmpty);

      // Case 2: Name changed
      final nameChanged = ProductSize(
        id: 's1',
        name: 'L',
        measurements: const BodyMeasurements(height: 170, weight: 60),
      );
      expect(original.getDirtyFields(nameChanged), {'name': 'L'});

      // Case 3: Measurement changed
      final measureChanged = ProductSize(
        id: 's1',
        name: 'M',
        measurements: const BodyMeasurements(height: 175, weight: 60),
      );
      expect(original.getDirtyFields(measureChanged), {'height': 175.0});

      // Case 4: Multiple changes
      final multiChanged = ProductSize(
        id: 's1',
        name: 'XL',
        measurements: const BodyMeasurements(height: 180, weight: 70),
      );
      final dirty = original.getDirtyFields(multiChanged);
      expect(dirty['name'], 'XL');
      expect(dirty['height'], 180.0);
      expect(dirty['weight'], 70.0);
    });
  });
}
