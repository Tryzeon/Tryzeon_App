import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/shared/models/product_model.dart';

class ShopService {
  static final _supabase = Supabase.instance.client;
  static const _productsTable = 'products';

  /// 獲取所有商品（包含店家資訊）
  static Future<List<Map<String, dynamic>>> getAllProducts({
    String sortBy = 'created_at',
    bool ascending = false,
    int? minPrice,
    int? maxPrice,
  }) async {
    try {
      // 查詢所有商品並關聯店家資訊
      // products.store_id = store-info.user_id
      dynamic query = _supabase
          .from(_productsTable)
          .select('''
            *,
            store-info!products_store_id_fkey(
              user_id,
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

      // 排序
      final response = await query.order(sortBy, ascending: ascending);

      return (response as List).map((item) {
        final product = Product.fromJson(item);
        final storeInfo = item['store-info'] as Map<String, dynamic>;
        
        return {
          'product': product,
          'storeName': storeInfo['store_name']
        };
      }).toList();
    } catch (e) {
      return [];
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

  /// 搜尋商品（包含商品名稱、類型和店家名稱）
  static Future<List<Map<String, dynamic>>> searchProducts(String query) async {
    try {
      // 先搜尋商品名稱和類型
      // products.store_id = store-info.user_id
      final productResponse = await _supabase
          .from(_productsTable)
          .select('''
            *,
            store-info!products_store_id_fkey(
              user_id,
              store_name
            )
          ''')
          .or('name.ilike.%$query%,type.ilike.%$query%')
          .order('created_at', ascending: false);

      // 再搜尋店家名稱
      final storeResponse = await _supabase
          .from(_productsTable)
          .select('''
            *,
            store-info!products_store_id_fkey(
              user_id,
              store_name
            )
          ''')
          .ilike('store-info.store_name', '%$query%')
          .order('created_at', ascending: false);

      // 合併結果並去重
      final Map<String, Map<String, dynamic>> uniqueProducts = {};
      
      // 處理商品搜尋結果
      for (final item in productResponse as List) {
        final product = Product.fromJson(item);
        final storeInfo = item['store-info'] as Map<String, dynamic>;
        uniqueProducts[product.id!] = {
          'product': product,
          'storeName': storeInfo['store_name']
        };
      }
      
      // 處理店家搜尋結果
      for (final item in storeResponse as List) {
        final product = Product.fromJson(item);
        final storeInfo = item['store-info'] as Map<String, dynamic>;
        if (!uniqueProducts.containsKey(product.id)) {
          uniqueProducts[product.id!] = {
            'product': product,
            'storeName': storeInfo['store_name']
          };
        }
      }

      return uniqueProducts.values.toList();
    } catch (e) {
      return [];
    }
  }
}