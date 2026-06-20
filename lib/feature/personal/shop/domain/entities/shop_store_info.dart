import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tryzeon/feature/common/store/domain/entities/store_channel.dart';

part 'shop_store_info.freezed.dart';

@freezed
sealed class ShopStoreInfo with _$ShopStoreInfo {
  const factory ShopStoreInfo({
    required final String id,
    required final String name,
    required final Set<StoreChannel> channels,
    final String? slug,
    final String? address,
    final String? logoUrl,
  }) = _ShopStoreInfo;
}
