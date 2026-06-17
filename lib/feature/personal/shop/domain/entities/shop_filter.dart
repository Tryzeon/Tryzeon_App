import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tryzeon/feature/common/clothing_style/entities/clothing_style.dart';
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
    final Set<String>? materials,
    final Set<ProductElasticity>? elasticities,
    final Set<String>? fits,
    final Set<ProductThickness>? thicknesses,
    final Set<ClothingStyle>? styles,
    final Set<ProductSeason>? seasons,
  }) = _ShopFilter;

  const ShopFilter._();

  /// Number of active sheet-managed filter groups (drives the filter button badge).
  int get activeFilterCount {
    var count = 0;
    if (channels?.isNotEmpty ?? false) count++;
    if (minPrice != null || maxPrice != null) count++;
    if (materials?.isNotEmpty ?? false) count++;
    if (elasticities?.isNotEmpty ?? false) count++;
    if (fits?.isNotEmpty ?? false) count++;
    if (thicknesses?.isNotEmpty ?? false) count++;
    if (styles?.isNotEmpty ?? false) count++;
    if (seasons?.isNotEmpty ?? false) count++;
    return count;
  }
}
