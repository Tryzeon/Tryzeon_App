import 'package:json_annotation/json_annotation.dart';

part 'product_category_model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class ProductCategoryModel {
  const ProductCategoryModel({
    required this.id,
    required this.name,
    this.imagePath,
    this.imageUrl,
  });

  factory ProductCategoryModel.fromJson(final Map<String, dynamic> json) =>
      _$ProductCategoryModelFromJson(json);

  final String id;
  final String name;
  final String? imagePath;
  @JsonKey(includeToJson: false)
  final String? imageUrl;

  Map<String, dynamic> toJson() => _$ProductCategoryModelToJson(this);
}
