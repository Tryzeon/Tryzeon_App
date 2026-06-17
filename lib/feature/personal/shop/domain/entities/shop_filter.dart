import 'package:freezed_annotation/freezed_annotation.dart';
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

    /// 進階篩選：材質（自由文字，包含比對）。
    final String? material,

    /// 進階篩選：彈性（多選 OR）。
    final Set<ProductElasticity>? elasticities,

    /// 進階篩選：版型（slim/regular/oversize，多選 OR）。
    final Set<String>? fits,

    /// 進階篩選：厚度（多選 OR）。
    final Set<ProductThickness>? thicknesses,

    /// 進階篩選：風格標籤（陣列重疊比對）。
    final Set<String>? styles,

    /// 進階篩選：季節（陣列重疊比對）。
    final Set<ProductSeason>? seasons,
  }) = _ShopFilter;
}
