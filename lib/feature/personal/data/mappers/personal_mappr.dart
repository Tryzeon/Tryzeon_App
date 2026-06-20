import 'package:auto_mappr_annotation/auto_mappr_annotation.dart';
import 'package:tryzeon/feature/common/product_attributes/entities/wardrobe_category.dart';

import '../../../../feature/common/clothing_style/entities/clothing_style.dart';
import '../../../../feature/common/measurements/data/mappers/measurements_mappr.dart';
import '../../../../feature/common/product_attributes/entities/product_attributes.dart';
import '../../../../feature/common/product_size/entities/product_size.dart';
import '../../../../feature/store/products/data/models/product_model.dart';
import '../../../common/store/domain/entities/store_channel.dart';
import '../../profile/data/collections/user_profile_collection.dart';
import '../../profile/data/models/user_profile_model.dart';
import '../../profile/domain/entities/age_range.dart';
import '../../profile/domain/entities/gender.dart';
import '../../profile/domain/entities/user_profile.dart';
import '../../shop/data/models/shop_product_model.dart';
import '../../shop/data/models/shop_store_info_model.dart';
import '../../shop/domain/entities/shop_product.dart';
import '../../shop/domain/entities/shop_store_info.dart';
import '../../subscription/data/collections/subscription_plan_collection.dart';
import '../../subscription/data/models/subscription_plan_model.dart';
import '../../wardrobe/data/collections/wardrobe_item_collection.dart';
import '../../wardrobe/data/models/wardrobe_item_model.dart';
import '../../wardrobe/domain/entities/wardrobe_item.dart';
import 'personal_mappr.auto_mappr.dart';

/// AutoMappr configuration for Personal feature
/// Handles UserProfile, WardrobeItem, SubscriptionPlan, ShopProduct, ShopStoreInfo mappings
/// Note: ProductSize mappings are defined here directly for ShopProduct.sizes dependency
/// Note: Measurements mappings are included via MeasurementsMappr (for ProductSize.measurements)
@AutoMappr(
  [
    // UserProfile mappings
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
    MapType<UserProfileModel, UserProfileCollection>(),
    MapType<UserProfileCollection, UserProfileModel>(),

    // WardrobeItem mappings
    MapType<WardrobeItemModel, WardrobeItem>(
      fields: [Field('category', custom: WardrobeItemMapprHelper.stringToCategory)],
    ),
    MapType<WardrobeItem, WardrobeItemModel>(
      fields: [Field('category', custom: WardrobeItemMapprHelper.categoryToString)],
    ),
    MapType<WardrobeItemModel, WardrobeItemCollection>(
      fields: [Field('itemId', from: 'id')],
    ),
    MapType<WardrobeItemCollection, WardrobeItemModel>(
      fields: [Field('id', from: 'itemId')],
    ),
    // ShopProduct mappings (read-only for consumer)
    MapType<ShopProductModel, ShopProduct>(
      fields: [
        Field('elasticity', custom: ShopProductMapprHelper.elasticityFromString),
        Field('thickness', custom: ShopProductMapprHelper.thicknessFromString),
        Field('seasons', custom: ShopProductMapprHelper.seasonsFromStrings),
        Field('styles', custom: ShopProductMapprHelper.stylesFromProductModelStrings),
      ],
    ),

    // ShopStoreInfo mappings (read-only for consumer)
    MapType<ShopStoreInfoModel, ShopStoreInfo>(
      fields: [Field('channels', custom: ShopStoreInfoMapprHelper.codesToChannelSet)],
    ),

    // ProductSize mappings (needed for ShopProduct.sizes)
    MapType<ProductSizeModel, ProductSize>(),

    // SubscriptionPlan mappings (Model ↔ Collection for local cache)
    MapType<SubscriptionPlanModel, SubscriptionPlanCollection>(
      fields: [Field('planId', from: 'id')],
    ),
    MapType<SubscriptionPlanCollection, SubscriptionPlanModel>(
      fields: [Field('id', from: 'planId')],
    ),
  ],
  includes: [
    MeasurementsMappr(), // ProductSize.measurements depends on Measurements mapping
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
