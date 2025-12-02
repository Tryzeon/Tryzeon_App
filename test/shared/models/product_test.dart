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
      expect(product.types, ['Shirt', 'Top']);
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
        types: ['Shirt', 'Top'],
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
  });
}
