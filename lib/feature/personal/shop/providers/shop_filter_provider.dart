import 'package:riverpod_annotation/riverpod_annotation.dart';
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
