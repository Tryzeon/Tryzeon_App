import 'package:json_annotation/json_annotation.dart';
import 'package:tryzeon/feature/common/store/data/models/store_order_contact_model.dart';

part 'store_profile_model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class StoreProfileModel {
  const StoreProfileModel({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    required this.channels,
    this.slug,
    this.address,
    this.latitude,
    this.longitude,
    this.logoPath,
    this.logoUrl,
    this.orderContacts = const [],
  });

  factory StoreProfileModel.fromJson(final Map<String, dynamic> json) =>
      _$StoreProfileModelFromJson(json);

  final String id;
  final String ownerId;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> channels;
  final String? slug;
  final String? address;
  final double? latitude;
  final double? longitude;
  final String? logoPath;
  final String? logoUrl;
  final List<StoreOrderContactModel> orderContacts;

  Map<String, dynamic> toJson() => _$StoreProfileModelToJson(this);
}
