import 'package:json_annotation/json_annotation.dart';

part 'product_category_model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class ProductCategoryModel {
  const ProductCategoryModel({
    required this.id,
    required this.name,
    this.gender,
    this.wardrobeCategory,
    this.imageMale,
    this.imageFemale,
    this.imageMaleUrl,
    this.imageFemaleUrl,
  });

  factory ProductCategoryModel.fromJson(final Map<String, dynamic> json) =>
      _$ProductCategoryModelFromJson(json);

  final String id;
  final String name;

  /// Applicability (raw value): `male`/`female`/`unisex`. `unisex` = both.
  final String? gender;
  final String? wardrobeCategory;

  /// Per-gender model imagery (R2 paths).
  final String? imageMale;
  final String? imageFemale;

  @JsonKey(includeToJson: false)
  final String? imageMaleUrl;
  @JsonKey(includeToJson: false)
  final String? imageFemaleUrl;

  Map<String, dynamic> toJson() => _$ProductCategoryModelToJson(this);
}
