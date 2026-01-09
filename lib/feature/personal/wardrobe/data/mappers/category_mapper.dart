import '../../domain/entities/wardrobe_category.dart';

class CategoryMapper {
  static String toApiString(final WardrobeCategory category) {
    return category.name;
  }

  static WardrobeCategory fromApiString(final String categoryString) {
    try {
      return WardrobeCategory.values.firstWhere(
        (final category) => category.name == categoryString,
      );
    } catch (e) {
      return WardrobeCategory.others;
    }
  }
}
