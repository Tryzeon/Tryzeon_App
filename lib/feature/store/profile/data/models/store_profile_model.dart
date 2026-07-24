import 'package:json_annotation/json_annotation.dart';
import 'package:tryzeon/feature/common/store/data/models/store_order_contact_model.dart';

part 'store_profile_model.g.dart';

/// [explicitToJson] keeps the nested order contacts plain maps rather than
/// [StoreOrderContactModel] instances, so `jsonDiff` can compare them
/// structurally instead of falling back to identity equality.
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
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

  static const unorderedJsonKeys = {'channels'};

  final String id;
  final String ownerId;
  final String name;
  @JsonKey(includeToJson: false)
  final DateTime createdAt;
  @JsonKey(includeToJson: false)
  final DateTime updatedAt;
  final List<String> channels;
  final String? slug;
  final String? address;
  final double? latitude;
  final double? longitude;
  final String? logoPath;
  @JsonKey(includeToJson: false)
  final String? logoUrl;
  final List<StoreOrderContactModel> orderContacts;

  Map<String, dynamic> toJson() => _$StoreProfileModelToJson(this);
}
