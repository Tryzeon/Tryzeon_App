import '../domain/entities/product_attributes.dart';
import '../domain/entities/wardrobe_category.dart';

const List<String> kFitPresets = ['合身', '常規', '大尺碼', 'oversize'];

const List<String> kMaterialPresets = [
  '棉',
  '麻',
  '羊毛',
  '蠶絲',
  '聚酯纖維',
  '尼龍',
  '嫘縈',
  '天絲',
  '萊卡',
  '混紡',
];

/// UI display label extension for [WardrobeCategory] in Presentation Layer.
/// This is the ONLY place where Chinese translations for it should exist.
extension CategoryDisplay on WardrobeCategory {
  /// Get the Chinese display name for UI.
  String get displayName => switch (this) {
    WardrobeCategory.top => '上衣',
    WardrobeCategory.bottoms => '下身',
    WardrobeCategory.outerwear => '外套',
    WardrobeCategory.sets => '套裝',
    WardrobeCategory.others => '其他',
  };

  /// Get all categories with their display names.
  static List<MapEntry<WardrobeCategory, String>> get allWithDisplayNames =>
      WardrobeCategory.values
          .map((final category) => MapEntry(category, category.displayName))
          .toList();
}

/// UI display label extension for [ProductGender] in Presentation Layer.
extension ProductGenderX on ProductGender {
  String get label => switch (this) {
    ProductGender.male => '男裝',
    ProductGender.female => '女裝',
    ProductGender.unisex => '中性',
  };
}

/// UI display label extension for [ProductElasticity] in Presentation Layer.
extension ProductElasticityX on ProductElasticity {
  String get label => switch (this) {
    ProductElasticity.none => '無',
    ProductElasticity.low => '低',
    ProductElasticity.medium => '中',
    ProductElasticity.high => '高',
  };
}

/// UI display label extension for [ProductThickness] in Presentation Layer.
extension ProductThicknessX on ProductThickness {
  String get label => switch (this) {
    ProductThickness.low => '薄',
    ProductThickness.medium => '中',
    ProductThickness.high => '厚',
  };
}

/// UI display label extension for [ProductSeason] in Presentation Layer.
extension ProductSeasonX on ProductSeason {
  String get label => switch (this) {
    ProductSeason.spring => '春',
    ProductSeason.summer => '夏',
    ProductSeason.autumn => '秋',
    ProductSeason.winter => '冬',
  };
}
