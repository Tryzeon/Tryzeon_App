import 'package:freezed_annotation/freezed_annotation.dart';

part 'shop_sort.freezed.dart';

@freezed
sealed class ShopSort with _$ShopSort {
  const factory ShopSort.latest() = ShopSortLatest;

  const factory ShopSort.priceLowToHigh() = ShopSortPriceLowToHigh;

  const factory ShopSort.priceHighToLow() = ShopSortPriceHighToLow;

  const factory ShopSort.proximity({
    required final double latitude,
    required final double longitude,
  }) = ShopSortProximity;
}
