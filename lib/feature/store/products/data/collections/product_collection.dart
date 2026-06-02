import 'package:isar_community/isar.dart';
import 'package:tryzeon/feature/common/measurements/collections/measurements_collection.dart';

part 'product_collection.g.dart';

@collection
class ProductCollection {
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

  List<ProductSizeCollection>? sizes;
}

@embedded
class ProductSizeCollection {
  late String id;
  late String productId;
  late String name;

  MeasurementsCollection? measurements;
  late DateTime createdAt;
  late DateTime updatedAt;
}
