import 'package:cached_query_flutter/cached_query_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/core/utils/app_logger.dart';

class ProductTypeService {
  static final _supabase = Supabase.instance.client;
  static const _typesTable = 'product_categories';

  static Query<List<String>> productTypesQuery() {
    return Query<List<String>>(
      key: ['product_categories'],
      queryFn: fetchProductTypes,
      config: QueryConfig(
        staleDuration: const Duration(days: 7),
        storageDeserializer: (final json) => List<String>.from(json),
      ),
    );
  }

  static Future<List<String>> fetchProductTypes() async {
    try {
      final response = await _supabase
          .from(_typesTable)
          .select('name_zh')
          .eq('is_active', true)
          .order('priority', ascending: true);

      return (response as List).map((final item) => item['name_zh'] as String).toList();
    } catch (e) {
      AppLogger.error('商品類型獲取失敗', e);
      throw '無法載入商品類型，請檢查網路連線';
    }
  }
}
