import 'package:json_annotation/json_annotation.dart';

part 'store_order_contact_model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class StoreOrderContactModel {
  const StoreOrderContactModel({required this.type, required this.value});

  factory StoreOrderContactModel.fromJson(final Map<String, dynamic> json) =>
      _$StoreOrderContactModelFromJson(json);

  final String type;
  final String value;

  Map<String, dynamic> toJson() => _$StoreOrderContactModelToJson(this);
}
