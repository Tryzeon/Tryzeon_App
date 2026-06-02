import 'package:auto_mappr_annotation/auto_mappr_annotation.dart';
import 'package:tryzeon/feature/common/store/domain/entities/store_channel.dart';

import '../../../../feature/common/clothing_style/entities/clothing_style.dart';
import '../../../../feature/common/measurements/data/mappers/measurements_mappr.dart';
import '../../../../feature/common/product_attributes/entities/product_attributes.dart';
import '../../analytics/data/collections/product_analytics_collection.dart';
import '../../analytics/data/models/product_analytics_summary_model.dart';
import '../../analytics/domain/entities/product_analytics_summary.dart';
import '../../products/data/collections/product_collection.dart';
import '../../products/data/models/product_model.dart';
import '../../products/domain/entities/product.dart';
import '../../profile/data/collections/store_profile_collection.dart';
import '../../profile/data/models/store_profile_model.dart';
import '../../profile/domain/entities/store_profile.dart';
import 'store_mappr.auto_mappr.dart';

/// AutoMappr configuration for Store feature
@AutoMappr(
  [
    // ProductSize mappings
    MapType<ProductSizeModel, ProductSize>(),
    MapType<ProductSize, ProductSizeModel>(),
    MapType<ProductSizeModel, ProductSizeCollection>(),
    MapType<ProductSizeCollection, ProductSizeModel>(),

    // Product mappings (String ↔ Enum conversion only at Model ↔ Entity boundary)
    MapType<ProductModel, Product>(
      fields: [
        Field('gender', custom: StoreMapprHelper.stringToGender),
        Field('elasticity', custom: StoreMapprHelper.stringToElasticity),
        Field('thickness', custom: StoreMapprHelper.stringToThickness),
        Field('styles', custom: StoreMapprHelper.stringsToStyles),
        Field('seasons', custom: StoreMapprHelper.stringsToSeasons),
      ],
    ),
    MapType<Product, ProductModel>(
      fields: [
        Field('gender', custom: StoreMapprHelper.genderToString),
        Field('elasticity', custom: StoreMapprHelper.elasticityToString),
        Field('thickness', custom: StoreMapprHelper.thicknessToString),
        Field('styles', custom: StoreMapprHelper.stylesToStrings),
        Field('seasons', custom: StoreMapprHelper.seasonsToStrings),
      ],
    ),

    // Collection mappings (String ↔ String, only field name mapping needed)
    MapType<ProductModel, ProductCollection>(fields: [Field('productId', from: 'id')]),
    MapType<ProductCollection, ProductModel>(fields: [Field('id', from: 'productId')]),

    // StoreProfile mappings — convert channels at Model ↔ Entity boundary
    MapType<StoreProfileModel, StoreProfile>(
      fields: [Field('channels', custom: StoreMapprHelper.codesToChannelSet)],
    ),
    MapType<StoreProfile, StoreProfileModel>(
      fields: [Field('channels', custom: StoreMapprHelper.channelSetToCodes)],
    ),
    MapType<StoreProfileModel, StoreProfileCollection>(
      fields: [Field('storeId', from: 'id')],
    ),
    MapType<StoreProfileCollection, StoreProfileModel>(
      fields: [Field('id', from: 'storeId')],
    ),

    // ProductAnalyticsSummary mappings
    MapType<ProductAnalyticsSummaryModel, ProductAnalyticsSummary>(),
    MapType<ProductAnalyticsSummaryModel, ProductAnalyticsCollection>(),
    MapType<ProductAnalyticsCollection, ProductAnalyticsSummaryModel>(),
  ],
  includes: [MeasurementsMappr()],
)
class StoreMappr extends $StoreMappr {
  const StoreMappr();
}

class StoreMapprHelper {
  // String to Enum conversions
  static ProductGender stringToGender(final ProductModel source) =>
      ProductGender.tryFromString(source.gender) ?? ProductGender.unisex;

  static ProductElasticity? stringToElasticity(final ProductModel source) =>
      ProductElasticity.tryFromString(source.elasticity);

  static ProductThickness? stringToThickness(final ProductModel source) =>
      ProductThickness.tryFromString(source.thickness);

  static List<ClothingStyle>? stringsToStyles(final ProductModel source) =>
      ClothingStyle.listFromStrings(source.styles);

  static List<ProductSeason>? stringsToSeasons(final ProductModel source) =>
      ProductSeason.listFromStrings(source.seasons);

  // Enum to String conversions
  static String genderToString(final Product source) => source.gender.value;

  static String? elasticityToString(final Product source) => source.elasticity?.value;

  static String? thicknessToString(final Product source) => source.thickness?.value;

  static List<String>? stylesToStrings(final Product source) =>
      source.styles?.map((final e) => e.value).toList();

  static List<String>? seasonsToStrings(final Product source) =>
      source.seasons?.map((final e) => e.value).toList();

  static Set<StoreChannel> codesToChannelSet(final StoreProfileModel source) =>
      StoreChannel.setFromCodes(source.channels);

  static List<String> channelSetToCodes(final StoreProfile source) =>
      StoreChannel.codesFromSet(source.channels);
}
