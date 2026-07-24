import 'package:isar_community/isar.dart';
import 'package:tryzeon/feature/common/product_size/data/collections/garment_measurements_embedded.dart';
import 'package:tryzeon/feature/common/product_size/data/collections/product_size_embedded.dart';
import 'package:tryzeon/feature/common/store/data/collections/store_order_contact_embedded.dart';

part 'shop_product_cache.g.dart';

@collection
class ShopProductCache {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String productId;

  late String name;
  late double price;
  late String categoryId;
  late List<String> imagePaths;
  late List<String> imageUrls;

  String? purchaseLink;
  String? material;
  String? elasticity;
  String? fit;
  String? thickness;
  List<String>? styles;
  List<String>? seasons;

  List<ProductSizeEmbedded>? sizes;

  late DateTime createdAt;
  late DateTime updatedAt;

  // 關聯的店鋪資訊 (必填，不可為 null)
  late ShopStoreInfoEmbedded storeInfo;
}

@embedded
class ShopStoreInfoEmbedded {
  late String storeId;
  late String name;
  late List<String> channels;
  String? address;
  String? logoUrl;
  List<StoreOrderContactEmbedded> orderContacts = [];
}
