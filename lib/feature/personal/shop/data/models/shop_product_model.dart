import 'package:json_annotation/json_annotation.dart';
import 'package:tryzeon/feature/common/product_size/data/models/product_size_model.dart';
import 'package:tryzeon/feature/personal/shop/data/models/shop_store_info_model.dart';

part 'shop_product_model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class ShopProductModel {
  const ShopProductModel({
    required this.storeInfo,
    required this.name,
    required this.categoryId,
    required this.price,
    required this.imagePaths,
    required this.imageUrls,
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    this.purchaseLink,
    this.material,
    this.elasticity,
    this.fit,
    this.thickness,
    this.styles,
    this.seasons,
    this.sizes,
  });

  factory ShopProductModel.fromJson(final Map<String, dynamic> json) =>
      _$ShopProductModelFromJson(json);

  @JsonKey(name: 'store_profiles', includeToJson: false)
  final ShopStoreInfoModel storeInfo;
  final String name;
  final String categoryId;
  final double price;
  final List<String> imagePaths;
  @JsonKey(includeToJson: false)
  final List<String> imageUrls;
  final String id;
  final String? purchaseLink;
  final String? material;
  final String? elasticity;
  final String? fit;
  final String? thickness;
  final List<String>? styles;
  final List<String>? seasons;
  @JsonKey(name: 'product_sizes', includeToJson: false)
  final List<ProductSizeModel>? sizes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() => _$ShopProductModelToJson(this);
}
