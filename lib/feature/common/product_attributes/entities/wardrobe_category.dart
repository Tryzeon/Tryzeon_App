/// Garment-type classification shared by the personal wardrobe and the store
/// catalog. Single-valued and mutually exclusive — a product/item is exactly
/// one of these. Lives in `common` because both the personal and store sides
/// depend on it.
enum WardrobeCategory {
  top('top'),
  pants('pants'),
  skirt('skirt'),
  jacket('jacket'),
  shoes('shoes'),
  accessories('accessories'),
  others('others');

  const WardrobeCategory(this.value);
  final String value;

  static WardrobeCategory? tryFromString(final String? value) =>
      WardrobeCategory.values.where((final e) => e.value == value).firstOrNull;
}
