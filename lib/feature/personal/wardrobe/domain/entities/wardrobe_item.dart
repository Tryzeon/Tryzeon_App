import 'package:equatable/equatable.dart';
import 'wardrobe_category.dart';

/// Domain entity representing a wardrobe item
/// Uses WardrobeCategory enum for type safety and business logic
class WardrobeItem extends Equatable {
  const WardrobeItem({
    this.id,
    required this.imagePath,
    required this.category,
    this.tags = const [],
  });

  final String? id;
  final String imagePath;
  final WardrobeCategory category;
  final List<String> tags;

  @override
  List<Object?> get props => [id, imagePath, category, tags];

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
