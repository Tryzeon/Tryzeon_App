import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/common/product_attributes/entities/product_attributes.dart';
import 'package:tryzeon/feature/common/store/domain/entities/store_channel.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/product_sort_option.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_filter.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_product.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_store_info.dart';
import 'package:tryzeon/feature/personal/shop/domain/repositories/product_repository.dart';
import 'package:tryzeon/feature/personal/shop/domain/usecases/list_shop_products.dart';
import 'package:typed_result/typed_result.dart';

class _CapturingRepo implements ProductRepository {
  Map<String, Object?>? captured;

  @override
  Future<Result<List<ShopProduct>, Failure>> listProducts({
    final String? storeId,
    final ProductSortOption sortOption = ProductSortOption.latest,
    final String? searchQuery,
    final int? minPrice,
    final int? maxPrice,
    final Set<String>? categories,
    final Set<StoreChannel>? channels,
    final ProductGender? gender,
    final String? material,
    final Set<ProductElasticity>? elasticities,
    final Set<String>? fits,
    final Set<ProductThickness>? thicknesses,
    final Set<String>? styles,
    final Set<ProductSeason>? seasons,
    final int? limit,
    final int? offset,
    final bool forceRefresh = false,
  }) async {
    captured = {
      'storeId': storeId,
      'searchQuery': searchQuery,
      'sortOption': sortOption,
      'minPrice': minPrice,
      'maxPrice': maxPrice,
      'categories': categories,
      'gender': gender,
      'channels': channels,
      'material': material,
      'elasticities': elasticities,
      'fits': fits,
      'thicknesses': thicknesses,
      'styles': styles,
      'seasons': seasons,
      'limit': limit,
      'offset': offset,
    };
    return const Ok([]);
  }

  @override
  Future<Result<ShopProduct, Failure>> getProduct(final String productId) =>
      throw UnimplementedError();

  @override
  Future<Result<ShopStoreInfo, Failure>> getStoreInfo(final String storeId) =>
      throw UnimplementedError();
}

void main() {
  test('maps ShopFilter advanced fields and pagination to the repository', () async {
    final repo = _CapturingRepo();
    final usecase = ListShopProducts(repo);

    await usecase(
      filter: const ShopFilter(
        storeId: 'store-1',
        searchQuery: 'shirt',
        sortOption: ProductSortOption.priceLowToHigh,
        minPrice: 100,
        maxPrice: 900,
        categories: {'cat-1'},
        gender: ProductGender.female,
        channels: {StoreChannel.online},
        material: 'linen',
        elasticities: {ProductElasticity.low},
        fits: {'oversize'},
        thicknesses: {ProductThickness.high},
        styles: {'minimal'},
        seasons: {ProductSeason.spring},
      ),
      limit: 24,
      offset: 48,
    );

    expect(repo.captured, isNotNull);
    expect(repo.captured!['storeId'], 'store-1');
    expect(repo.captured!['searchQuery'], 'shirt');
    expect(
      repo.captured!['sortOption'],
      ProductSortOption.priceLowToHigh,
    );
    expect(repo.captured!['minPrice'], 100);
    expect(repo.captured!['maxPrice'], 900);
    expect(repo.captured!['categories'], {'cat-1'});
    expect(repo.captured!['gender'], ProductGender.female);
    expect(repo.captured!['channels'], {StoreChannel.online});
    expect(repo.captured!['material'], 'linen');
    expect(repo.captured!['elasticities'], {ProductElasticity.low});
    expect(repo.captured!['fits'], {'oversize'});
    expect(repo.captured!['thicknesses'], {ProductThickness.high});
    expect(repo.captured!['styles'], {'minimal'});
    expect(repo.captured!['seasons'], {ProductSeason.spring});
    expect(repo.captured!['limit'], 24);
    expect(repo.captured!['offset'], 48);
  });
}
