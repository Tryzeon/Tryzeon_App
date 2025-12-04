import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/feature/personal/personal/data/wardrobe_item_model.dart';

void main() {
  group('WardrobeItem', () {
    test('fromJson parses valid JSON correctly', () {
      final json = {
        'id': 'item_123',
        'image_path': 'path/to/image.jpg',
        'category': 'top',
        'tags': ['summer', 'casual'],
      };

      final item = WardrobeItem.fromJson(json);

      expect(item.id, 'item_123');
      expect(item.imagePath, 'path/to/image.jpg');
      expect(item.category, 'top');
      expect(item.tags, ['summer', 'casual']);
    });

    test('toJson converts object to valid JSON', () {
      final item = WardrobeItem(
        id: 'item_123',
        imagePath: 'path/to/image.jpg',
        category: 'top',
        tags: ['summer', 'casual'],
      );

      final json = item.toJson();

      expect(json['id'], 'item_123');
      expect(json['image_path'], 'path/to/image.jpg');
      expect(json['category'], 'top');
      expect(json['tags'], ['summer', 'casual']);
    });

    test('copyWith creates new instance with updated values', () {
      final original = WardrobeItem(
        id: 'item_123',
        imagePath: 'path/to/image.jpg',
        category: 'top',
        tags: ['summer'],
      );

      final copy = original.copyWith(
        category: 'pants',
        tags: ['winter'],
      );

      expect(copy.id, original.id); // Unchanged
      expect(copy.imagePath, original.imagePath); // Unchanged
      expect(copy.category, 'pants'); // Changed
      expect(copy.tags, ['winter']); // Changed

      final copyImage = original.copyWith(imagePath: 'new/path.jpg');
      expect(copyImage.imagePath, 'new/path.jpg');
    });
  });
}
