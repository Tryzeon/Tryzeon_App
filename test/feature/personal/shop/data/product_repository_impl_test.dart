import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/core/domain/cache/cache_lookup.dart';
import 'package:tryzeon/core/error/exceptions.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/common/clothing_style/entities/clothing_style.dart';
import 'package:tryzeon/feature/common/product_attributes/entities/product_attributes.dart';
import 'package:tryzeon/feature/common/store/domain/entities/store_channel.dart';
import 'package:tryzeon/feature/personal/shop/data/datasources/shop_local_datasource.dart';
import 'package:tryzeon/feature/personal/shop/data/datasources/shop_remote_datasource.dart';
import 'package:tryzeon/feature/personal/shop/data/models/shop_product_model.dart';
import 'package:tryzeon/feature/personal/shop/data/repositories/product_repository_impl.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_sort.dart';
import 'package:typed_result/typed_result.dart';

class _RecordingRemote implements ShopRemoteDataSource {
  Map<String, Object?>? captured;

  @override
  Future<List<ShopProductModel>> listProducts({
    final String? storeId,
    final String? searchQuery,
    final ShopSort sort = const ShopSort.latest(),
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
      'sort': sort,
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
  dynamic noSuchMethod(final Invocation invocation) => super.noSuchMethod(invocation);
}

class _NoopLocal implements ShopLocalDataSource {
  @override
  Future<void> saveProducts(final List<ShopProductModel> products) async {}

  @override
  Future<CacheLookup<ShopProductModel>> getProductById(final String productId) async =>
      const CacheMiss<ShopProductModel>();

  @override
  Future<void> saveProduct(final ShopProductModel product) async {}

  @override
  dynamic noSuchMethod(final Invocation invocation) => super.noSuchMethod(invocation);
}

class _NotFoundRemote implements ShopRemoteDataSource {
  @override
  Future<ShopProductModel> getProduct(final String productId) async {
    throw const NotFoundException();
  }

  @override
  Future<Map<String, dynamic>> getStoreProfile(final String storeId) async {
    throw const NotFoundException();
  }

  @override
  dynamic noSuchMethod(final Invocation invocation) => super.noSuchMethod(invocation);
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

  test('forwards the proximity sort to the datasource', () async {
    final remote = _RecordingRemote();
    final repo = ProductRepositoryImpl(
      remoteDataSource: remote,
      localDataSource: _NoopLocal(),
    );

    await repo.listProducts(
      sort: const ShopSort.proximity(latitude: 25.033, longitude: 121.565),
    );

    expect(
      remote.captured!['sort'],
      const ShopSort.proximity(latitude: 25.033, longitude: 121.565),
    );
  });

  test('getProduct returns NotFoundFailure when the product does not exist', () async {
    final repo = ProductRepositoryImpl(
      remoteDataSource: _NotFoundRemote(),
      localDataSource: _NoopLocal(),
    );

    final result = await repo.getProduct('missing-id');

    expect(result.isFailure, isTrue);
    expect(result.getError(), isA<NotFoundFailure>());
  });

  test('getStoreInfo returns NotFoundFailure when the store does not exist', () async {
    final repo = ProductRepositoryImpl(
      remoteDataSource: _NotFoundRemote(),
      localDataSource: _NoopLocal(),
    );

    final result = await repo.getStoreInfo('missing-id');

    expect(result.isFailure, isTrue);
    expect(result.getError(), isA<NotFoundFailure>());
  });
}
