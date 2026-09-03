import '../domain/entities/product_attributes.dart';
import '../domain/entities/wardrobe_category.dart';

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

/// The ONLY place where Chinese labels for [WardrobeCategory] should exist.
extension CategoryDisplay on WardrobeCategory {
  String get displayName => switch (this) {
    WardrobeCategory.top => '上衣',
    WardrobeCategory.bottoms => '下身',
    WardrobeCategory.outerwear => '外套',
    WardrobeCategory.sets => '套裝',
    WardrobeCategory.others => '其他',
  };

  static List<MapEntry<WardrobeCategory, String>> get allWithDisplayNames =>
      WardrobeCategory.values
          .map((final category) => MapEntry(category, category.displayName))
          .toList();
}

extension ProductGenderX on ProductGender {
  String get label => switch (this) {
    ProductGender.male => '男裝',
    ProductGender.female => '女裝',
    ProductGender.unisex => '中性',
  };
}

extension ProductFitX on ProductFit {
  String get label => switch (this) {
    ProductFit.slim => '合身',
    ProductFit.regular => '常規',
    ProductFit.loose => '寬鬆',
    ProductFit.oversize => 'Oversize',
  };
}

extension ProductElasticityX on ProductElasticity {
  String get label => switch (this) {
    ProductElasticity.none => '無',
    ProductElasticity.low => '低',
    ProductElasticity.medium => '中',
    ProductElasticity.high => '高',
  };
}

extension ProductThicknessX on ProductThickness {
  String get label => switch (this) {
    ProductThickness.low => '薄',
    ProductThickness.medium => '中',
    ProductThickness.high => '厚',
  };
}

extension ProductSeasonX on ProductSeason {
  String get label => switch (this) {
    ProductSeason.spring => '春',
    ProductSeason.summer => '夏',
    ProductSeason.autumn => '秋',
    ProductSeason.winter => '冬',
  };
}
