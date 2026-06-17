import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/feature/common/clothing_style/entities/clothing_style.dart';
import 'package:tryzeon/feature/common/product_attributes/entities/product_attributes.dart';
import 'package:tryzeon/feature/common/store/domain/entities/store_channel.dart';
import 'package:tryzeon/feature/personal/shop/data/datasources/shop_local_datasource.dart';
import 'package:tryzeon/feature/personal/shop/data/datasources/shop_remote_datasource.dart';
import 'package:tryzeon/feature/personal/shop/data/models/shop_product_model.dart';
import 'package:tryzeon/feature/personal/shop/data/repositories/product_repository_impl.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/product_sort_option.dart';

class _RecordingRemote implements ShopRemoteDataSource {
  Map<String, Object?>? captured;

  @override
  Future<List<ShopProductModel>> listProducts({
    final String? storeId,
    final String? searchQuery,
    final ProductSortOption sortOption = ProductSortOption.latest,
    final int? minPrice,
    final int? maxPrice,
    final Set<String>? categories,
    final Set<StoreChannel>? channels,
    final ProductGender? gender,
    final Set<String>? materials,
    final Set<ProductElasticity>? elasticities,
    final Set<String>? fits,
    final Set<ProductThickness>? thicknesses,
    final Set<ClothingStyle>? styles,
    final Set<ProductSeason>? seasons,
    final int? limit,
    final int? offset,
  }) async {
    captured = {
      'materials': materials,
      'elasticities': elasticities,
      'fits': fits,
      'thicknesses': thicknesses,
      'styles': styles,
      'seasons': seasons,
      'limit': limit,
      'offset': offset,
    };
    return <ShopProductModel>[];
  }

  @override
  dynamic noSuchMethod(final Invocation invocation) =>
      super.noSuchMethod(invocation);
}

class _NoopLocal implements ShopLocalDataSource {
  @override
  Future<void> saveProducts(final List<ShopProductModel> products) async {}

  @override
  dynamic noSuchMethod(final Invocation invocation) =>
      super.noSuchMethod(invocation);
}

void main() {
  test('forwards advanced filters and pagination to the datasource', () async {
    final remote = _RecordingRemote();
    final repo = ProductRepositoryImpl(
      remoteDataSource: remote,
      localDataSource: _NoopLocal(),
    );

    final result = await repo.listProducts(
      materials: {'wool'},
      elasticities: {ProductElasticity.medium},
      fits: {'slim'},
      thicknesses: {ProductThickness.high},
      styles: {ClothingStyle.streetwear},
      seasons: {ProductSeason.winter},
      limit: 30,
      offset: 60,
    );

    expect(result.isSuccess, isTrue);
    expect(remote.captured, isNotNull);
    expect(remote.captured!['materials'], {'wool'});
    expect(remote.captured!['elasticities'], {ProductElasticity.medium});
    expect(remote.captured!['fits'], {'slim'});
    expect(remote.captured!['thicknesses'], {ProductThickness.high});
    expect(remote.captured!['styles'], {ClothingStyle.streetwear});
    expect(remote.captured!['seasons'], {ProductSeason.winter});
    expect(remote.captured!['limit'], 30);
    expect(remote.captured!['offset'], 60);
  });
}
