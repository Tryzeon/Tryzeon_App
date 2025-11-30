import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/shared/models/product.dart';
import 'package:tryzeon/shared/models/result.dart';
import 'package:tryzeon/shared/utils/app_logger.dart';

class ShopService {
  static final _supabase = Supabase.instance.client;
  static const _productsTable = 'products';

  /// 獲取所有商品（包含店家資訊）
  static Future<Result<List<Product>>> getProducts({
    final String? searchQuery,
    final String sortBy = 'created_at',
    final bool ascending = false,
    final int? minPrice,
    final int? maxPrice,
    final List<String>? types,
  }) async {
    try {
      // 查詢所有商品並關聯店家資訊和尺寸資訊
      // products.store_id = store_profile.store_id
      dynamic query = _supabase.from(_productsTable).select('''
            *,
            store_profile(
              store_id,
              name
            ),
            product_sizes(*)
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
        query = query.overlaps('type', types);
      }

      // 排序
      final response = await query.order(sortBy, ascending: ascending);

      final searchResult = (response as List)
          .map((final item) => Product.fromJson(item))
          .toList();

      return Result.success(data: searchResult);
    } catch (e) {
      return Result.failure('獲取商品列表失敗', error: e);
    }
  }

  /// 增加商品的虛擬試穿點擊次數
  static Future<void> incrementTryonCount(final String productId) async {
    try {
      await _supabase.rpc(
        'increment_tryon_count',
        params: {'product_uuid': productId},
      );
    } catch (e) {
      AppLogger.error('Error incrementing tryon count', e);
    }
  }

  /// 增加商品的購買連結點擊次數
  static Future<void> incrementPurchaseClickCount(
    final String productId,
  ) async {
    try {
      await _supabase.rpc(
        'increment_purchase_click_count',
        params: {'product_uuid': productId},
      );
    } catch (e) {
      AppLogger.error('Error incrementing purchase click count', e);
    }
  }
}
