import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/shared/services/cache_service.dart';
import 'package:tryzeon/shared/models/result.dart';

class ProductTypeService {
  static final _supabase = Supabase.instance.client;
  static const _typesTable = 'product_types';

  static const _cacheKey = 'product_types_cache';

  static Future<Result<List<String>>> getProductTypesList({bool forceRefresh = false}) async {
    try {
      if (!forceRefresh) {
        final cachedData = await CacheService.loadList(_cacheKey);
        if (cachedData != null) {
          final types = List<String>.from(cachedData);
          return Result.success(data: types);
        }
      }

      final response = await _supabase
          .from(_typesTable)
          .select('name_zh')
          .order('priority', ascending: true);

      final types = (response as List)
          .map((item) => item['name_zh'] as String)
          .toList();

      await CacheService.saveList(_cacheKey, types);

      return Result.success(data: types);
    } catch (e) {
      return Result.failure('取得商品類型失敗: ${e.toString()}');
    }
  }
}