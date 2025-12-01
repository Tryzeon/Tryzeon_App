import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/shared/models/result.dart';
import 'package:tryzeon/shared/services/cache_service.dart';

class ProductTypeService {
  static final _supabase = Supabase.instance.client;
  static const _typesTable = 'product_types';

  static const _cacheKey = 'product_types_cache';

  static Future<Result<List<String>>> getProductTypes({
    final bool forceRefresh = false,
  }) async {
    try {
      if (!forceRefresh) {
        final cachedData = await CacheService.loadFromCache(_cacheKey);
        if (cachedData != null) {
          final cachedProductTypes = List<String>.from(cachedData);
          return Result.success(data: cachedProductTypes);
        }
      }

      final response = await _supabase
          .from(_typesTable)
          .select('name_zh')
          .order('priority', ascending: true);

      final productTypes = (response as List)
          .map((final item) => item['name_zh'] as String)
          .toList();

      await CacheService.saveToCache(_cacheKey, productTypes);

      return Result.success(data: productTypes);
    } catch (e) {
      return Result.failure('商品類型取得失敗', error: e);
    }
  }
}
