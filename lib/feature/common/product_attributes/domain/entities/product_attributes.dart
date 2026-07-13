enum ProductGender {
  male('male'),
  female('female'),
  unisex('unisex');

  const ProductGender(this.value);
  final String value;

  static ProductGender? tryFromString(final String? value) =>
      ProductGender.values.where((final e) => e.value == value).firstOrNull;
}

enum ProductElasticity {
  none('none'),
  low('low'),
  medium('medium'),
  high('high');

  const ProductElasticity(this.value);
  final String value;

  static ProductElasticity? tryFromString(final String? value) =>
      ProductElasticity.values.where((final e) => e.value == value).firstOrNull;
}

enum ProductThickness {
  low('low'),
  medium('medium'),
  high('high');

  const ProductThickness(this.value);
  final String value;

  static ProductThickness? tryFromString(final String? value) =>
      ProductThickness.values.where((final e) => e.value == value).firstOrNull;
}

enum ProductSeason {
  spring('spring'),
  summer('summer'),
  autumn('autumn'),
  winter('winter');

  const ProductSeason(this.value);
  final String value;

  static ProductSeason? tryFromString(final String? value) =>
      ProductSeason.values.where((final e) => e.value == value).firstOrNull;

  static List<ProductSeason>? listFromStrings(final Iterable<String>? values) =>
      values?.map(tryFromString).whereType<ProductSeason>().toList();
}
