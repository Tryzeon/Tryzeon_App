import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/shared/models/product_model.dart';

class ShopService {
  static final _supabase = Supabase.instance.client;
  static const _productsTable = 'products_info';

  /// 獲取所有商品（包含店家資訊）
  static Future<ShopResult> getProducts({
    String sortBy = 'created_at',
    bool ascending = false,
    int? minPrice,
    int? maxPrice,
    List<String>? types,
  }) async {
    try {
      // 查詢所有商品並關聯店家資訊
      // products.store_id = store_profile.store_id
      dynamic query = _supabase
          .from(_productsTable)
          .select('''
            *,
            store_profile!products_store_id_fkey(
              store_id,
              store_name
            )
          ''');

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
          .map((item) => Product.fromJson(item))
          .toList();

      return ShopResult.success(searchResult);
    } catch (e) {
      return ShopResult.failure(e.toString());
    }
  }

  /// 搜尋商品（包含商品名稱、類型和店家名稱）
  static Future<ShopResult> searchProducts(String query) async {
    try {
      final response = await _supabase
        .from(_productsTable)
        .select('''
        *,
        store_profile!products_store_id_fkey(
          store_id,
          store_name
        )
        ''')
        .or('name.ilike.%$query%,type.cs.{$query}')
        .order('created_at', ascending: false);

      final searchResult = (response as List)
          .map((item) => Product.fromJson(item))
          .toList();

      return ShopResult.success(searchResult);
    } catch (e) {
      return ShopResult.failure(e.toString());
    }
  }

  /// 增加商品的虛擬試穿點擊次數
  static Future<void> incrementTryonCount(String productId) async {
    try {
      await _supabase.rpc('increment_tryon_count', params: {
        'product_uuid': productId,
      });
    } catch (e) {
      print("Error incrementing tryon count: $e");
    }
  }

  /// 增加商品的購買連結點擊次數
  static Future<void> incrementPurchaseClickCount(String productId) async {
    try {
      await _supabase.rpc('increment_purchase_click_count', params: {
        'product_uuid': productId,
      });
    } catch (e) {
      print("Error incrementing purchase click count: $e");
    }
  }
}

class ShopResult {
  final bool success;
  final List<Product>? products;
  final String? errorMessage;

  ShopResult({
    required this.success,
    this.products,
    this.errorMessage,
  });

  factory ShopResult.success(List<Product> products) {
    return ShopResult(success: true, products: products);
  }

  factory ShopResult.failure(String errorMessage) {
    return ShopResult(success: false, errorMessage: errorMessage);
  }
}