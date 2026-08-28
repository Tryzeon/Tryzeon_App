import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tryzeon/core/data/collections/cache_entry.dart';
import 'package:tryzeon/feature/auth/data/collections/auth_settings_cache.dart';
import 'package:tryzeon/feature/common/product_category/data/collections/product_category_cache.dart';
import 'package:tryzeon/feature/personal/profile/data/collections/user_profile_cache.dart';
import 'package:tryzeon/feature/personal/subscription/data/collections/subscription_tier_cache.dart';
import 'package:tryzeon/feature/personal/wardrobe/data/collections/wardrobe_item_cache.dart';
import 'package:tryzeon/feature/store/analytics/data/collections/product_analytics_cache.dart';
import 'package:tryzeon/feature/store/product/data/collections/product_cache.dart';
import 'package:tryzeon/feature/store/profile/data/collections/store_profile_cache.dart';

class IsarService {
  IsarService() {
    db = openDB();
  }
  late Future<Isar> db;

  Future<Isar> openDB() async {
    if (Isar.instanceNames.isEmpty) {
      final dir = await getApplicationDocumentsDirectory();
      return Isar.open(
        [
          CacheEntrySchema,
          AuthSettingsCacheSchema,
          ProductCategoryCacheSchema,
          UserProfileCacheSchema,
          WardrobeItemCacheSchema,
          ProductCacheSchema,
          StoreProfileCacheSchema,
          SubscriptionTierCacheSchema,
          ProductAnalyticsCacheSchema,
        ],
        directory: dir.path,
        inspector: false,
      );
    }

    return Future.value(Isar.getInstance());
  }
}
