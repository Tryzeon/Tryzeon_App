import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/feature/common/clothing_style/entities/clothing_style.dart';
import 'package:tryzeon/feature/common/product_attributes/entities/product_attributes.dart';
import 'package:tryzeon/feature/common/store/domain/entities/store_channel.dart';
import 'package:tryzeon/feature/personal/shop/data/datasources/shop_remote_datasource.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_sort.dart';

void main() {
  test('sortParams maps each ShopSort variant to its column and direction', () {
    expect(ShopRemoteDataSource.sortParams(const ShopSort.latest()), (
      column: 'created_at',
      ascending: false,
    ));
    expect(ShopRemoteDataSource.sortParams(const ShopSort.priceLowToHigh()), (
      column: 'price',
      ascending: true,
    ));
    expect(ShopRemoteDataSource.sortParams(const ShopSort.priceHighToLow()), (
      column: 'price',
      ascending: false,
    ));
    expect(
      ShopRemoteDataSource.sortParams(
        const ShopSort.proximity(latitude: 25.033, longitude: 121.565),
      ),
      (column: 'proximity', ascending: true),
    );
  });

  test('buildListProductsParams forwards user coordinates as p_user_lat/lng', () {
    final params = ShopRemoteDataSource.buildListProductsParams(
      sortColumn: 'proximity',
      sortAscending: true,
      userLatitude: 25.033,
      userLongitude: 121.565,
    );

    expect(params['p_user_lat'], 25.033);
    expect(params['p_user_lng'], 121.565);
  });

  test('buildListProductsParams sends null coordinates by default', () {
    final params = ShopRemoteDataSource.buildListProductsParams(
      sortColumn: 'created_at',
      sortAscending: false,
    );

    expect(params['p_user_lat'], isNull);
    expect(params['p_user_lng'], isNull);
  });

  test('maps enums to their string values and forwards pagination', () {
    final params = ShopRemoteDataSource.buildListProductsParams(
      sortColumn: 'price',
      sortAscending: true,
      elasticities: {ProductElasticity.high},
      thicknesses: {ProductThickness.low},
      seasons: {ProductSeason.summer},
      fits: {'slim'},
      styles: {ClothingStyle.casual},
      materials: {'棉'},
      limit: 20,
      offset: 40,
    );

    expect(params['p_elasticities'], ['high']);
    expect(params['p_thicknesses'], ['low']);
    expect(params['p_seasons'], ['summer']);
    expect(params['p_fits'], ['slim']);
    expect(params['p_styles'], ['casual']);
    expect(params['p_materials'], ['棉']);
    expect(params['p_limit'], 20);
    expect(params['p_offset'], 40);
    expect(params['p_sort_column'], 'price');
    expect(params['p_sort_ascending'], true);
  });

  test('empty or null collections become null params', () {
    final params = ShopRemoteDataSource.buildListProductsParams(
      sortColumn: 'created_at',
      sortAscending: false,
      categories: const {},
      elasticities: const {},
      styles: null,
    );

    expect(params['p_category_ids'], isNull);
    expect(params['p_elasticities'], isNull);
    expect(params['p_styles'], isNull);
  });

  test('all-channels selection sends null (no channel filter)', () {
    final params = ShopRemoteDataSource.buildListProductsParams(
      sortColumn: 'created_at',
      sortAscending: false,
      channels: StoreChannel.all,
    );
    expect(params['p_channels'], isNull);
  });
}
