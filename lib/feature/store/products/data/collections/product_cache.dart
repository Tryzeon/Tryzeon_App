import 'package:isar_community/isar.dart';
import 'package:tryzeon/feature/common/measurements/data/collections/measurements_embedded.dart';
import 'package:tryzeon/feature/common/product_size/data/collections/product_size_embedded.dart';

part 'product_cache.g.dart';

@collection
class ProductCache {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String productId;

  @Index()
  late String storeId;
  late String name;
  late List<String> categoryIds;
  late double price;
  late List<String> imagePaths;
  late List<String> imageUrls;
  String? gender;
  String? purchaseLink;
  String? material;

  String? elasticity;
  String? fit;
  String? thickness;

  List<String>? styles;
  List<String>? seasons;

  late DateTime createdAt;
  late DateTime updatedAt;

  List<ProductSizeEmbedded>? sizes;
}
