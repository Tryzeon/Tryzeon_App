import 'package:auto_mappr_annotation/auto_mappr_annotation.dart';
import 'package:tryzeon/feature/common/product_attributes/domain/entities/wardrobe_category.dart';

import '../../../../feature/common/body_measurements/data/mappers/body_measurements_mappr.dart';
import '../../../../feature/common/clothing_style/domain/entities/clothing_style.dart';
import '../../../../feature/common/product_attributes/domain/entities/product_attributes.dart';
import '../../../../feature/common/product_size/data/mappers/garment_measurements_mappr.dart';
import '../../../../feature/common/product_size/domain/entities/product_size.dart';
import '../../../../feature/store/product/data/models/product_model.dart';
import '../../../common/store/data/models/store_order_contact_model.dart';
import '../../../common/store/domain/entities/store_channel.dart';
import '../../../common/store/domain/entities/store_order_contact.dart';
import '../../profile/data/collections/user_profile_cache.dart';
import '../../profile/data/models/user_profile_model.dart';
import '../../profile/domain/entities/age_range.dart';
import '../../profile/domain/entities/gender.dart';
import '../../profile/domain/entities/user_profile.dart';
import '../../shop/data/models/shop_product_model.dart';
import '../../shop/data/models/shop_store_info_model.dart';
import '../../shop/domain/entities/shop_product.dart';
import '../../shop/domain/entities/shop_store_info.dart';
import '../../subscription/data/collections/subscription_tier_cache.dart';
import '../../subscription/data/models/subscription_tier_model.dart';
import '../../wardrobe/data/collections/wardrobe_item_cache.dart';
import '../../wardrobe/data/models/wardrobe_item_model.dart';
import '../../wardrobe/domain/entities/wardrobe_item.dart';
import 'personal_mappr.auto_mappr.dart';

@AutoMappr(
  [
    MapType<UserProfileModel, UserProfile>(
      fields: [
        Field('gender', custom: UserProfileMapprHelper.genderFromString),
        Field('ageRange', custom: UserProfileMapprHelper.ageRangeFromString),
        Field(
          'stylePreferences',
          custom: UserProfileMapprHelper.stylePreferencesFromStrings,
        ),
      ],
    ),
    MapType<UserProfile, UserProfileModel>(
      fields: [
        Field('gender', custom: UserProfileMapprHelper.genderToString),
        Field('ageRange', custom: UserProfileMapprHelper.ageRangeToString),
        Field(
          'stylePreferences',
          custom: UserProfileMapprHelper.stylePreferencesToStrings,
        ),
      ],
    ),
    MapType<UserProfileModel, UserProfileCache>(),
    MapType<UserProfileCache, UserProfileModel>(),

    MapType<WardrobeItemModel, WardrobeItem>(
      fields: [Field('category', custom: WardrobeItemMapprHelper.stringToCategory)],
    ),
    MapType<WardrobeItem, WardrobeItemModel>(
      fields: [Field('category', custom: WardrobeItemMapprHelper.categoryToString)],
    ),
    MapType<WardrobeItemModel, WardrobeItemCache>(fields: [Field('itemId', from: 'id')]),
    MapType<WardrobeItemCache, WardrobeItemModel>(fields: [Field('id', from: 'itemId')]),
    MapType<ShopProductModel, ShopProduct>(
      fields: [
        Field('elasticity', custom: ShopProductMapprHelper.elasticityFromString),
        Field('fit', custom: ShopProductMapprHelper.fitFromString),
        Field('thickness', custom: ShopProductMapprHelper.thicknessFromString),
        Field('seasons', custom: ShopProductMapprHelper.seasonsFromStrings),
        Field('styles', custom: ShopProductMapprHelper.stylesFromProductModelStrings),
      ],
    ),

    MapType<StoreOrderContactModel, StoreOrderContact>(
      fields: [Field('type', custom: ShopStoreInfoMapprHelper.codeToOrderContactType)],
    ),

    MapType<ShopStoreInfoModel, ShopStoreInfo>(
      fields: [Field('channels', custom: ShopStoreInfoMapprHelper.codesToChannelSet)],
    ),

    MapType<ProductSizeModel, ProductSize>(),

    MapType<SubscriptionTierModel, SubscriptionTierCache>(
      fields: [Field('tier', from: 'id')],
    ),
    MapType<SubscriptionTierCache, SubscriptionTierModel>(
      fields: [Field('id', from: 'tier')],
    ),
  ],
  includes: [
    BodyMeasurementsMappr(), // UserProfile.measurements
    GarmentMeasurementsMappr(), // ProductSize.measurements
  ],
)
class PersonalMappr extends $PersonalMappr {
  const PersonalMappr();
}

class WardrobeItemMapprHelper {
  static WardrobeCategory stringToCategory(final WardrobeItemModel source) =>
      WardrobeCategory.tryFromString(source.category) ?? WardrobeCategory.others;

  static String categoryToString(final WardrobeItem source) => source.category.value;
}

class ShopProductMapprHelper {
  static ProductElasticity? elasticityFromString(final ShopProductModel source) =>
      ProductElasticity.tryFromString(source.elasticity);

  static ProductFit? fitFromString(final ShopProductModel source) =>
      ProductFit.tryFromString(source.fit);

  static ProductThickness? thicknessFromString(final ShopProductModel source) =>
      ProductThickness.tryFromString(source.thickness);

  static List<ProductSeason>? seasonsFromStrings(final ShopProductModel source) =>
      ProductSeason.listFromStrings(source.seasons);

  static List<ClothingStyle>? stylesFromProductModelStrings(
    final ShopProductModel source,
  ) => ClothingStyle.listFromStrings(source.styles);
}

class ShopStoreInfoMapprHelper {
  static Set<StoreChannel> codesToChannelSet(final ShopStoreInfoModel source) =>
      StoreChannel.setFromCodes(source.channels);

  static OrderContactType codeToOrderContactType(final StoreOrderContactModel source) =>
      OrderContactType.fromCode(source.type) ?? OrderContactType.line;
}

class UserProfileMapprHelper {
  static Gender? genderFromString(final UserProfileModel source) =>
      Gender.tryFromString(source.gender);

  static String? genderToString(final UserProfile source) => source.gender?.value;

  static AgeRange? ageRangeFromString(final UserProfileModel source) =>
      AgeRange.tryFromString(source.ageRange);

  static String? ageRangeToString(final UserProfile source) => source.ageRange?.value;

  static List<ClothingStyle>? stylePreferencesFromStrings(
    final UserProfileModel source,
  ) => ClothingStyle.listFromStrings(source.stylePreferences);

  static List<String>? stylePreferencesToStrings(final UserProfile source) =>
      source.stylePreferences?.map((final e) => e.value).toList();
}
