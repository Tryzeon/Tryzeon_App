import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/core/services/location_service.dart';
import 'package:tryzeon/feature/personal/shop/data/models/shop_product_model.dart';
import 'package:tryzeon/feature/personal/shop/domain/enums/product_sort_option.dart';

class ShopRemoteDataSource {
  ShopRemoteDataSource(this._supabaseClient);
  final SupabaseClient _supabaseClient;
  static const _productsTable = 'products';

  Future<List<ShopProductModel>> fetchProducts({
    final String? searchQuery,
    final ProductSortOption sortOption = ProductSortOption.latest,
    final int? minPrice,
    final int? maxPrice,
    final Set<String>? types,
    final UserLocation? userLocation,
  }) async {
    // 查詢所有商品並關聯店家資訊和尺寸資訊
    dynamic query = _supabaseClient.from(_productsTable).select('''
          *,
          product_sizes(*),
          store_profile!inner(*)
        ''');

    // 搜尋過濾（商品名稱或類型）
    if (searchQuery != null && searchQuery.isNotEmpty) {
      query = query.or('name.ilike.%$searchQuery%,type.cs.{$searchQuery}');
    }

    // 價格區間過濾
    if (minPrice != null) {
      query = query.gte('price', minPrice);
    }
    if (maxPrice != null) {
      query = query.lte('price', maxPrice);
    }
    // 類型過濾（使用 PostgreSQL 陣列 overlap 操作符）
    if (types != null && types.isNotEmpty) {
      query = query.overlaps('type', types.toList());
    }

    // 排序邏輯
    final String dbSortColumn;
    final bool isAscending;

    switch (sortOption) {
      case ProductSortOption.priceLowToHigh:
        dbSortColumn = 'price';
        isAscending = true;
      case ProductSortOption.priceHighToLow:
        dbSortColumn = 'price';
        isAscending = false;
      case ProductSortOption.latest:
        dbSortColumn = 'created_at';
        isAscending = false;
    }

    // 排序
    final response = await query.order(dbSortColumn, ascending: isAscending);

    // 將結果轉換為 Model
    var products = (response as List).map((final item) {
      final map = Map<String, dynamic>.from(item);
      final imagePath = map['image_path'] as String?;
      if (imagePath != null) {
        map['image_url'] = getProductImageUrl(imagePath);
      }
      return ShopProductModel.fromJson(map);
    }).toList();

    // 若有使用者位置，依接近度排序：同區優先 > 同城市 > 其他
    if (userLocation != null) {
      final sameDistrict = <ShopProductModel>[];
      final sameCity = <ShopProductModel>[];
      final otherCity = <ShopProductModel>[];

      for (final product in products) {
        if (userLocation.isSameDistrict(product.storeAddress)) {
          sameDistrict.add(product);
        } else if (userLocation.isSameCity(product.storeAddress)) {
          sameCity.add(product);
        } else {
          otherCity.add(product);
        }
      }

      products = [...sameDistrict, ...sameCity, ...otherCity];
    }

    return products;
  }

  String getProductImageUrl(final String imagePath) {
    return _supabaseClient.storage.from('store').getPublicUrl(imagePath);
  }

  Future<void> incrementTryonCount(final String productId) async {
    await _supabaseClient.rpc(
      'increment_tryon_count',
      params: {'product_uuid': productId},
    );
  }

  Future<void> incrementPurchaseClickCount(final String productId) async {
    await _supabaseClient.rpc(
      'increment_purchase_click_count',
      params: {'product_uuid': productId},
    );
  }
}
