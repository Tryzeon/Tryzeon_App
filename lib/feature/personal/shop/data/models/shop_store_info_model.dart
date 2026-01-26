import 'package:tryzeon/feature/personal/shop/domain/entities/shop_store_info.dart';

class ShopStoreInfoModel extends ShopStoreInfo {
  const ShopStoreInfoModel({required super.id, super.name, super.address});

  factory ShopStoreInfoModel.fromJson(final Map<String, dynamic> json) {
    return ShopStoreInfoModel(
      id: json['id'] as String,
      name: json['name'] as String?,
      address: json['address'] as String?,
    );
  }
}
