import 'package:tryzeon/core/utils/app_logger.dart';
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
    } catch (e, stackTrace) {
      AppLogger.debug('Unknown category string: $categoryString', e, stackTrace);
      return WardrobeCategory.others;
    }
  }
}
