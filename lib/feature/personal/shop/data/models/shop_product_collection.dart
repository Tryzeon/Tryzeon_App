import 'package:isar_community/isar.dart';
import 'package:tryzeon/feature/common/measurements/collections/measurements_collection.dart';
import 'package:tryzeon/feature/common/store/data/collections/store_order_contact_embedded.dart';

part 'shop_product_collection.g.dart';

@collection
class ShopProductCollection {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String productId;

  late String name;
  late double price;
  late List<String> categoryIds;
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
class ProductSizeEmbedded {
  late String sizeId;
  late String productId;
  late String name;
  MeasurementsCollection? measurements;
  late DateTime createdAt;
  late DateTime updatedAt;
}

@embedded
class ShopStoreInfoEmbedded {
  late String storeId;
  late String name;
  late List<String> channels;
  String? address;
  String? logoUrl;
  String? logoPath;
  List<StoreOrderContactEmbedded> orderContacts = [];
}
