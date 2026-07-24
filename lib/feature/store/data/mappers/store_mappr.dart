import 'package:auto_mappr_annotation/auto_mappr_annotation.dart';
import 'package:tryzeon/feature/common/store/data/collections/store_order_contact_embedded.dart';
import 'package:tryzeon/feature/common/store/data/models/store_order_contact_model.dart';
import 'package:tryzeon/feature/common/store/domain/entities/store_channel.dart';
import 'package:tryzeon/feature/common/store/domain/entities/store_order_contact.dart';

import '../../../../feature/common/clothing_style/domain/entities/clothing_style.dart';
import '../../../../feature/common/product_attributes/domain/entities/product_attributes.dart';
import '../../../../feature/common/product_size/data/collections/product_size_embedded.dart';
import '../../../../feature/common/product_size/data/mappers/garment_measurements_mappr.dart';
import '../../analytics/data/collections/product_analytics_cache.dart';
import '../../analytics/data/models/product_analytics_summary_model.dart';
import '../../analytics/domain/entities/product_analytics_summary.dart';
import '../../products/data/collections/product_cache.dart';
import '../../products/data/models/product_model.dart';
import '../../products/domain/entities/product.dart';
import '../../profile/data/collections/store_profile_cache.dart';
import '../../profile/data/models/store_profile_model.dart';
import '../../profile/domain/entities/store_profile.dart';
import 'store_mappr.auto_mappr.dart';

/// AutoMappr configuration for Store feature
@AutoMappr(
  [
    // ProductSize mappings
    MapType<ProductSizeModel, ProductSize>(),
    MapType<ProductSize, ProductSizeModel>(),
    MapType<ProductSizeModel, ProductSizeEmbedded>(),
    MapType<ProductSizeEmbedded, ProductSizeModel>(),

    // Product mappings (String ↔ Enum conversion only at Model ↔ Entity boundary)
    MapType<ProductModel, Product>(
      fields: [
        Field('gender', custom: StoreMapprHelper.stringToGender),
        Field('elasticity', custom: StoreMapprHelper.stringToElasticity),
        Field('thickness', custom: StoreMapprHelper.stringToThickness),
        Field('categoryIds', custom: StoreMapprHelper.categoryIdsToSet),
        Field('styles', custom: StoreMapprHelper.stringsToStyles),
        Field('seasons', custom: StoreMapprHelper.stringsToSeasons),
      ],
    ),
    MapType<Product, ProductModel>(
      fields: [
        Field('gender', custom: StoreMapprHelper.genderToString),
        Field('elasticity', custom: StoreMapprHelper.elasticityToString),
        Field('thickness', custom: StoreMapprHelper.thicknessToString),
        Field('categoryIds', custom: StoreMapprHelper.categoryIdsToList),
        Field('styles', custom: StoreMapprHelper.stylesToStrings),
        Field('seasons', custom: StoreMapprHelper.seasonsToStrings),
      ],
    ),

    // Collection mappings (String ↔ String, only field name mapping needed)
    MapType<ProductModel, ProductCache>(fields: [Field('productId', from: 'id')]),
    MapType<ProductCache, ProductModel>(fields: [Field('id', from: 'productId')]),

    // StoreOrderContact mappings (enum <-> code at Model <-> Entity boundary)
    MapType<StoreOrderContactModel, StoreOrderContact>(
      fields: [Field('type', custom: StoreMapprHelper.codeToOrderContactType)],
    ),
    MapType<StoreOrderContact, StoreOrderContactModel>(
      fields: [Field('type', custom: StoreMapprHelper.orderContactTypeToCode)],
    ),
    MapType<StoreOrderContactModel, StoreOrderContactEmbedded>(),
    MapType<StoreOrderContactEmbedded, StoreOrderContactModel>(),

    // StoreProfile mappings — convert channels at Model ↔ Entity boundary
    MapType<StoreProfileModel, StoreProfile>(
      fields: [Field('channels', custom: StoreMapprHelper.codesToChannelSet)],
    ),
    MapType<StoreProfile, StoreProfileModel>(
      fields: [Field('channels', custom: StoreMapprHelper.channelSetToCodes)],
    ),
    MapType<StoreProfileModel, StoreProfileCache>(fields: [Field('storeId', from: 'id')]),
    MapType<StoreProfileCache, StoreProfileModel>(fields: [Field('id', from: 'storeId')]),

    // ProductAnalyticsSummary mappings
    MapType<ProductAnalyticsSummaryModel, ProductAnalyticsSummary>(),
    MapType<ProductAnalyticsSummaryModel, ProductAnalyticsCache>(),
    MapType<ProductAnalyticsCache, ProductAnalyticsSummaryModel>(),
  ],
  includes: [GarmentMeasurementsMappr()],
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

  static Set<String> categoryIdsToSet(final ProductModel source) =>
      source.categoryIds.toSet();

  static Set<ClothingStyle>? stringsToStyles(final ProductModel source) =>
      ClothingStyle.listFromStrings(source.styles)?.toSet();

  static Set<ProductSeason>? stringsToSeasons(final ProductModel source) =>
      ProductSeason.listFromStrings(source.seasons)?.toSet();

  // Enum to String conversions
  static String genderToString(final Product source) => source.gender.value;

  static String? elasticityToString(final Product source) => source.elasticity?.value;

  static String? thicknessToString(final Product source) => source.thickness?.value;

  static List<String> categoryIdsToList(final Product source) =>
      source.categoryIds.toList()..sort();

  static List<String>? stylesToStrings(final Product source) {
    final styles = source.styles;
    return styles == null ? null : ClothingStyle.stringsFromSet(styles);
  }

  static List<String>? seasonsToStrings(final Product source) {
    final seasons = source.seasons;
    return seasons == null ? null : ProductSeason.stringsFromSet(seasons);
  }

  static Set<StoreChannel> codesToChannelSet(final StoreProfileModel source) =>
      StoreChannel.setFromCodes(source.channels);

  static List<String> channelSetToCodes(final StoreProfile source) =>
      StoreChannel.codesFromSet(source.channels);

  static OrderContactType codeToOrderContactType(final StoreOrderContactModel source) =>
      OrderContactType.fromCode(source.type) ?? OrderContactType.line;

  static String orderContactTypeToCode(final StoreOrderContact source) =>
      source.type.code;
}
