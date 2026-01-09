/// Wardrobe item category enum representing business domain concepts.
enum WardrobeCategory {
  top,
  pants,
  skirt,
  jacket,
  shoes,
  accessories,
  others;

  /// Get all available categories
  static List<WardrobeCategory> get all => WardrobeCategory.values;
}
