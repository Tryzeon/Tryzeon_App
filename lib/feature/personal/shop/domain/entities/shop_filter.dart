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
    final Set<StoreChannel>? channels,
    final String? material,
    final Set<ProductElasticity>? elasticities,
    final Set<String>? fits,
    final Set<ProductThickness>? thicknesses,
    final Set<String>? styles,
    final Set<ProductSeason>? seasons,
  }) = _ShopFilter;
}
