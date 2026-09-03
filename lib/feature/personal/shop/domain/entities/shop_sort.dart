import 'package:freezed_annotation/freezed_annotation.dart';

part 'shop_sort.freezed.dart';

/// 商品排序方式。
///
/// `proximity` 變體自帶使用者座標,因此「依距離排序」在型別上不可能缺少
/// 座標,其餘排序也不可能夾帶座標 —— 把無效狀態消除在編譯期,呼叫端也
/// 只需要一個 `setSort` 入口。
@freezed
sealed class ShopSort with _$ShopSort {
  /// 綜合(預設):最新優先。
  const factory ShopSort.latest() = ShopSortLatest;

  const factory ShopSort.priceLowToHigh() = ShopSortPriceLowToHigh;

  const factory ShopSort.priceHighToLow() = ShopSortPriceHighToLow;

  /// 依與使用者座標的距離由近到遠。
  const factory ShopSort.proximity({
    required final double latitude,
    required final double longitude,
  }) = ShopSortProximity;
}
