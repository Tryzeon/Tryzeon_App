import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tryzeon/feature/common/clothing_style/entities/clothing_style.dart';
import 'package:tryzeon/feature/common/product_attributes/entities/product_attributes.dart';
import 'package:tryzeon/feature/common/store/domain/entities/store_channel.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/product_sort_option.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_filter.dart';

part 'shop_filter_provider.g.dart';

@riverpod
class ShopFilterNotifier extends _$ShopFilterNotifier {
  @override
  ShopFilter build() => const ShopFilter();

  void setSearch(final String? query) {
    final normalized = (query == null || query.isEmpty) ? null : query;
    state = state.copyWith(searchQuery: normalized);
  }

  void setSort(final ProductSortOption option) {
    state = state.copyWith(sortOption: option);
  }

  void setPriceRange({final int? min, final int? max}) {
    state = state.copyWith(minPrice: min, maxPrice: max);
  }

  void setChannels(final Set<StoreChannel>? channels) {
    state = state.copyWith(
      channels: (channels == null || channels.isEmpty) ? null : channels,
    );
  }

  void setMaterials(final Set<String>? materials) {
    state = state.copyWith(
      materials: (materials == null || materials.isEmpty) ? null : materials,
    );
  }

  void setElasticities(final Set<ProductElasticity>? elasticities) {
    state = state.copyWith(
      elasticities: (elasticities == null || elasticities.isEmpty) ? null : elasticities,
    );
  }

  void setFits(final Set<String>? fits) {
    state = state.copyWith(fits: (fits == null || fits.isEmpty) ? null : fits);
  }

  void setThicknesses(final Set<ProductThickness>? thicknesses) {
    state = state.copyWith(
      thicknesses: (thicknesses == null || thicknesses.isEmpty) ? null : thicknesses,
    );
  }

  void setStyles(final Set<ClothingStyle>? styles) {
    state = state.copyWith(styles: (styles == null || styles.isEmpty) ? null : styles);
  }

  void setSeasons(final Set<ProductSeason>? seasons) {
    state = state.copyWith(
      seasons: (seasons == null || seasons.isEmpty) ? null : seasons,
    );
  }

  void setCategories(final Set<String> categoryIds) {
    state = state.copyWith(categories: categoryIds);
  }

  void setGender(final ProductGender? gender) {
    state = state.copyWith(gender: gender, categories: null);
  }

  void reset() {
    state = const ShopFilter();
  }
}
