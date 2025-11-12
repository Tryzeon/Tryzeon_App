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

      final products = (response as List).map((item) {
        final product = Product.fromJson(item);
        final storeInfo = item['store_profile'] as Map<String, dynamic>;

        return {
          'product': product,
          'storeName': storeInfo['store_name']
        };
      }).toList();

      return ShopResult.success(products);
    } catch (e) {
      return ShopResult.failure(e.toString());
    }
  }

  /// 搜尋商品（包含商品名稱、類型和店家名稱）
  static Future<ShopResult> searchProducts(String query) async {
    try {
      // 先搜尋商品名稱和類型
      // products.store_id = store_profile.store_id
      final productResponse = await _supabase
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

      // 再搜尋店家名稱
      final storeResponse = await _supabase
          .from(_productsTable)
          .select('''
            *,
            store_profile!products_store_id_fkey(
              store_id,
              store_name
            )
          ''')
          .ilike('store_profile.store_name', '%$query%')
          .order('created_at', ascending: false);

      // 合併結果並去重
      final Map<String, Map<String, dynamic>> uniqueProducts = {};

      // 處理商品搜尋結果
      for (final item in productResponse as List) {
        final product = Product.fromJson(item);
        final storeInfo = item['store_profile'] as Map<String, dynamic>;
        uniqueProducts[product.id!] = {
          'product': product,
          'storeName': storeInfo['store_name']
        };
      }

      // 處理店家搜尋結果
      for (final item in storeResponse as List) {
        final product = Product.fromJson(item);
        final storeInfo = item['store_profile'] as Map<String, dynamic>;
        if (!uniqueProducts.containsKey(product.id)) {
          uniqueProducts[product.id!] = {
            'product': product,
            'storeName': storeInfo['store_name']
          };
        }
      }

      return ShopResult.success(uniqueProducts.values.toList());
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
      // 靜默失敗，不影響用戶體驗
    }
  }

  /// 增加商品的購買連結點擊次數
  static Future<void> incrementPurchaseClickCount(String productId) async {
    try {
      await _supabase.rpc('increment_purchase_click_count', params: {
        'product_uuid': productId,
      });
    } catch (e) {
      // 靜默失敗，不影響用戶體驗
    }
  }
}

class ShopResult {
  final bool success;
  final List<Map<String, dynamic>>? products;
  final String? errorMessage;

  ShopResult({
    required this.success,
    this.products,
    this.errorMessage,
  });

  factory ShopResult.success(List<Map<String, dynamic>> products) {
    return ShopResult(success: true, products: products);
  }

  factory ShopResult.failure(String errorMessage) {
    return ShopResult(success: false, errorMessage: errorMessage);
  }
}