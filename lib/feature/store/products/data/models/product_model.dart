import 'package:json_annotation/json_annotation.dart';
import 'package:tryzeon/feature/common/product_size/data/models/product_size_model.dart';

export 'package:tryzeon/feature/common/product_size/data/models/product_size_model.dart';

part 'product_model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class ProductModel {
  const ProductModel({
    required this.storeId,
    required this.name,
    required this.categoryIds,
    required this.price,
    required this.imagePaths,
    required this.imageUrls,
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    this.gender,
    this.purchaseLink,
    this.material,
    this.elasticity,
    this.fit,
    this.thickness,
    this.styles,
    this.seasons,
    this.sizes,
  });

  factory ProductModel.fromJson(final Map<String, dynamic> json) =>
      _$ProductModelFromJson(json);

  final String storeId;
  final String name;
  final List<String> categoryIds;
  final double price;
  final List<String> imagePaths;
  @JsonKey(includeToJson: false)
  final List<String> imageUrls;
  final String id;
  final String? gender;
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

  Map<String, dynamic> toJson() => _$ProductModelToJson(this);
}
