import '../../domain/entities/wardrobe_category.dart';

/// UI layer extension for displaying WardrobeCategory in Chinese
/// This is the ONLY place where Chinese translations should exist
extension CategoryDisplay on WardrobeCategory {
  /// Get the Chinese display name for UI
  String get displayName {
    switch (this) {
      case WardrobeCategory.top:
        return '上衣';
      case WardrobeCategory.pants:
        return '褲子';
      case WardrobeCategory.skirt:
        return '裙子';
      case WardrobeCategory.jacket:
        return '外套';
      case WardrobeCategory.shoes:
        return '鞋子';
      case WardrobeCategory.accessories:
        return '配件';
      case WardrobeCategory.others:
        return '其他';
    }
  }

  /// Get all categories with their display names
  static List<MapEntry<WardrobeCategory, String>> get allWithDisplayNames {
    return WardrobeCategory.all
        .map((final category) => MapEntry(category, category.displayName))
        .toList();
  }
}
