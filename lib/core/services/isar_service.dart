import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tryzeon/feature/auth/data/collections/auth_settings_collection.dart';
import 'package:tryzeon/feature/common/product_categories/data/collections/product_category_collection.dart';
import 'package:tryzeon/feature/personal/profile/data/collections/user_profile_collection.dart';
import 'package:tryzeon/feature/personal/wardrobe/data/collections/wardrobe_item_collection.dart';
import 'package:tryzeon/feature/store/products/data/collections/product_collection.dart';
import 'package:tryzeon/feature/store/profile/data/collections/store_profile_collection.dart';

final isarServiceProvider = Provider<IsarService>((final ref) => IsarService());

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
          AuthSettingsCollectionSchema,
          ProductCategoryCollectionSchema,
          UserProfileCollectionSchema,
          WardrobeItemCollectionSchema,
          ProductCollectionSchema,
          StoreProfileCollectionSchema,
        ],
        directory: dir.path,
        inspector: true,
      );
    }

    return Future.value(Isar.getInstance());
  }
}
