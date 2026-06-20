import 'package:json_annotation/json_annotation.dart';

part 'shop_store_info_model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class ShopStoreInfoModel {
  const ShopStoreInfoModel({
    required this.id,
    required this.name,
    required this.channels,
    this.slug,
    this.address,
    this.logoUrl,
  });

  factory ShopStoreInfoModel.fromJson(final Map<String, dynamic> json) =>
      _$ShopStoreInfoModelFromJson(json);

  final String id;
  final String name;
  final List<String> channels;
  final String? slug;
  final String? address;
  final String? logoUrl;

  Map<String, dynamic> toJson() => _$ShopStoreInfoModelToJson(this);
}
