import 'package:cached_query_flutter/cached_query_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/shared/utils/app_logger.dart';
import 'package:typed_result/typed_result.dart';

class ProductTypeService {
  static final _supabase = Supabase.instance.client;
  static const _typesTable = 'product_types';

  static Future<Result<List<String>, String>> getProductTypes({
    final bool forceRefresh = false,
  }) async {
    try {
      final query = Query<List<String>>(
        key: ['product_types'],
        queryFn: () async {
          final response = await _supabase
              .from(_typesTable)
              .select('name_zh')
              .order('priority', ascending: true);

          return (response as List)
              .map((final item) => item['name_zh'] as String)
              .toList();
        },
      );

      final state = forceRefresh ? await query.refetch() : await query.fetch();

      if (state.error != null) {
        AppLogger.error('商品類型取得失敗', state.error);
        return const Err('無法取得商品分類，請稍後再試');
      }

      return Ok(state.data!);
    } catch (e) {
      AppLogger.error('商品類型取得失敗', e);
      return const Err('無法取得商品分類，請稍後再試');
    }
  }
}
