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
import '../../product/data/collections/product_cache.dart';
import '../../product/data/models/product_model.dart';
import '../../product/domain/entities/product.dart';
import '../../profile/data/collections/store_profile_cache.dart';
import '../../profile/data/models/store_profile_model.dart';
import '../../profile/domain/entities/store_profile.dart';
import 'store_mappr.auto_mappr.dart';

@AutoMappr(
  [
    MapType<ProductSizeModel, ProductSize>(),
    MapType<ProductSize, ProductSizeModel>(),
    MapType<ProductSizeModel, ProductSizeEmbedded>(),
    MapType<ProductSizeEmbedded, ProductSizeModel>(),

    MapType<ProductModel, Product>(
      fields: [
        Field('status', custom: StoreMapprHelper.stringToStatus),
        Field('gender', custom: StoreMapprHelper.stringToGender),
        Field('elasticity', custom: StoreMapprHelper.stringToElasticity),
        Field('fit', custom: StoreMapprHelper.stringToFit),
        Field('thickness', custom: StoreMapprHelper.stringToThickness),
        Field('styles', custom: StoreMapprHelper.stringsToStyles),
        Field('seasons', custom: StoreMapprHelper.stringsToSeasons),
      ],
    ),
    MapType<Product, ProductModel>(
      fields: [
        Field('status', custom: StoreMapprHelper.statusToString),
        Field('gender', custom: StoreMapprHelper.genderToString),
        Field('elasticity', custom: StoreMapprHelper.elasticityToString),
        Field('fit', custom: StoreMapprHelper.fitToString),
        Field('thickness', custom: StoreMapprHelper.thicknessToString),
        Field('styles', custom: StoreMapprHelper.stylesToStrings),
        Field('seasons', custom: StoreMapprHelper.seasonsToStrings),
      ],
    ),

    MapType<ProductModel, ProductCache>(fields: [Field('productId', from: 'id')]),
    MapType<ProductCache, ProductModel>(fields: [Field('id', from: 'productId')]),

    MapType<StoreOrderContactModel, StoreOrderContact>(
      fields: [Field('type', custom: StoreMapprHelper.codeToOrderContactType)],
    ),
    MapType<StoreOrderContact, StoreOrderContactModel>(
      fields: [Field('type', custom: StoreMapprHelper.orderContactTypeToCode)],
    ),
    MapType<StoreOrderContactModel, StoreOrderContactEmbedded>(),
    MapType<StoreOrderContactEmbedded, StoreOrderContactModel>(),

    MapType<StoreProfileModel, StoreProfile>(
      fields: [Field('channels', custom: StoreMapprHelper.codesToChannelSet)],
    ),
    MapType<StoreProfile, StoreProfileModel>(
      fields: [Field('channels', custom: StoreMapprHelper.channelSetToCodes)],
    ),
    MapType<StoreProfileModel, StoreProfileCache>(fields: [Field('storeId', from: 'id')]),
    MapType<StoreProfileCache, StoreProfileModel>(fields: [Field('id', from: 'storeId')]),

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
  static ProductStatus stringToStatus(final ProductModel source) =>
      ProductStatus.tryFromString(source.status) ?? ProductStatus.active;

  static ProductGender stringToGender(final ProductModel source) =>
      ProductGender.tryFromString(source.gender) ?? ProductGender.unisex;

  static ProductElasticity? stringToElasticity(final ProductModel source) =>
      ProductElasticity.tryFromString(source.elasticity);

  static ProductFit? stringToFit(final ProductModel source) =>
      ProductFit.tryFromString(source.fit);

  static ProductThickness? stringToThickness(final ProductModel source) =>
      ProductThickness.tryFromString(source.thickness);

  static Set<ClothingStyle>? stringsToStyles(final ProductModel source) =>
      ClothingStyle.listFromStrings(source.styles)?.toSet();

  static Set<ProductSeason>? stringsToSeasons(final ProductModel source) =>
      ProductSeason.listFromStrings(source.seasons)?.toSet();

  static String statusToString(final Product source) => source.status.value;

  static String genderToString(final Product source) => source.gender.value;

  static String? elasticityToString(final Product source) => source.elasticity?.value;

  static String? fitToString(final Product source) => source.fit?.value;

  static String? thicknessToString(final Product source) => source.thickness?.value;

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
