import 'package:isar/isar.dart';

part 'product_collection.g.dart';

@collection
class ProductCollection {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String productId;

  late String storeId;
  late String name;
  List<String>? types;
  double? price;
  String? imagePath;
  String? imageUrl;
  String? purchaseLink;
  int? tryonCount;
  int? purchaseClickCount;
  DateTime? createdAt;
  DateTime? updatedAt;
  String? storeName;

  List<ProductSizeCollection>? sizes;
}

@embedded
class ProductSizeCollection {
  String? id;
  String? productId;
  String? name;

  double? height;
  double? weight;
  double? chest;
  double? waist;
  double? hips;
  double? shoulderWidth;
  double? sleeveLength;

}
