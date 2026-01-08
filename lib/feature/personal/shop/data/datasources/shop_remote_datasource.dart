import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/feature/personal/shop/data/models/shop_product_model.dart';

class ShopRemoteDataSource {
  ShopRemoteDataSource(this._supabaseClient);
  final SupabaseClient _supabaseClient;
  static const _productsTable = 'products';

  Future<List<ShopProductModel>> fetchProducts({
    final String? searchQuery,
    final String sortBy = 'created_at',
    final bool ascending = false,
    final int? minPrice,
    final int? maxPrice,
    final Set<String>? types,
  }) async {
    // 查詢所有商品並關聯店家資訊和尺寸資訊
    dynamic query = _supabaseClient.from(_productsTable).select('''
          *,
          product_sizes(*),
          store_profile(*)
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

    // 排序
    final response = await query.order(sortBy, ascending: ascending);

    return (response as List)
        .map((final item) => ShopProductModel.fromJson(item))
        .toList();
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
