import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tryzeon/core/modules/location/domain/entities/user_location.dart';
import 'package:tryzeon/feature/common/product_attributes/entities/product_attributes.dart';
import 'package:tryzeon/feature/common/store/domain/entities/store_channel.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/product_sort_option.dart';

part 'shop_filter.freezed.dart';

@freezed
sealed class ShopFilter with _$ShopFilter {
  const factory ShopFilter({
    final String? storeId,
    final String? searchQuery,
    @Default(ProductSortOption.latest) final ProductSortOption sortOption,
    final int? minPrice,
    final int? maxPrice,
    final Set<String>? categories,
    final ProductGender? gender,
    @Default(StoreChannel.all) final Set<StoreChannel> channels,

    /// 使用者位置（用於附近店家排序）
    final UserLocation? userLocation,
  }) = _ShopFilter;
}
