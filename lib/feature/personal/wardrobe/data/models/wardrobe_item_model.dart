import '../../domain/entities/wardrobe_item.dart';
import '../mappers/category_mapper.dart';

class WardrobeItemModel extends WardrobeItem {
  const WardrobeItemModel({
    super.id,
    required super.imagePath,
    required super.category,
    super.tags = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory WardrobeItemModel.fromJson(final Map<String, dynamic> json) {
    return WardrobeItemModel(
      id: json['id'] as String?,
      imagePath: json['image_path'] as String,
      category: CategoryMapper.fromApiString(json['category'] as String),
      tags: json['tags'] != null ? List<String>.from(json['tags'] as List) : const [],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  final DateTime? createdAt;
  final DateTime? updatedAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'image_path': imagePath,
      'category': CategoryMapper.toApiString(category),
      'tags': tags,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
