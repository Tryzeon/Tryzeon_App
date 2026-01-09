import 'wardrobe_category.dart';

/// Domain entity representing a wardrobe item
/// Uses WardrobeCategory enum for type safety and business logic
class WardrobeItem {
  WardrobeItem({
    this.id,
    required this.imagePath,
    required this.category,
    this.tags = const [],
  });

  final String? id;
  final String imagePath;
  final WardrobeCategory category;
  final List<String> tags;

  WardrobeItem copyWith({
    final String? id,
    final String? imagePath,
    final WardrobeCategory? category,
    final List<String>? tags,
  }) {
    return WardrobeItem(
      id: id ?? this.id,
      imagePath: imagePath ?? this.imagePath,
      category: category ?? this.category,
      tags: tags ?? this.tags,
    );
  }
}
