import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/common/product_categories/domain/repositories/product_category_repository.dart';
import 'package:tryzeon/feature/common/product_categories/domain/usecases/expand_category_ids.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_filter.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_product.dart';
import 'package:tryzeon/feature/personal/shop/domain/repositories/product_repository.dart';
import 'package:typed_result/typed_result.dart';

class GetShopProducts {
  GetShopProducts(this._repository, this._categoryRepository, this._expandCategoryIds);

  final ProductRepository _repository;
  final ProductCategoryRepository _categoryRepository;
  final ExpandCategoryIds _expandCategoryIds;

  Future<Result<List<ShopProduct>, Failure>> call({
    required final ShopFilter filter,
    final bool forceRefresh = false,
  }) async {
    final categories = await _expandedCategories(filter.categories);
    return _repository.getProducts(
      storeId: filter.storeId,
      searchQuery: filter.searchQuery,
      sortOption: filter.sortOption,
      minPrice: filter.minPrice,
      maxPrice: filter.maxPrice,
      categories: categories,
      channels: filter.channels,
      userLocation: filter.userLocation,
      forceRefresh: forceRefresh,
    );
  }

  Future<Set<String>?> _expandedCategories(final Set<String>? selected) async {
    if (selected == null || selected.isEmpty) return selected;
    final result = await _categoryRepository.getProductCategories();
    if (result.isSuccess) {
      return _expandCategoryIds(result.get()!, selected);
    }
    return selected;
  }
}
