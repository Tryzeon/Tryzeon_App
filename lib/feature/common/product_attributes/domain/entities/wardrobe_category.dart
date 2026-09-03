/// Garment-type classification shared by the personal wardrobe and the store
/// catalog.
enum WardrobeCategory {
  top('top'),
  bottoms('bottoms'),
  outerwear('outerwear'),
  sets('sets'),
  others('others');

  const WardrobeCategory(this.value);
  final String value;

  static WardrobeCategory? tryFromString(final String? value) =>
      WardrobeCategory.values.where((final e) => e.value == value).firstOrNull;
}
