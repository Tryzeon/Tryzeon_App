import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/shared/services/cache_service.dart';

class ProductTypeService {
  static final _supabase = Supabase.instance.client;
  static const _typesTable = 'product_types';

  static const _cacheKey = 'product_types_cache';

  static Future<List<String>> getProductTypesList({bool forceRefresh = false}) async {
    try {
      if (!forceRefresh) {
        final cachedData = await CacheService.loadList(_cacheKey);
        if (cachedData != null) {
          return List<String>.from(cachedData);
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

      return types;
    } catch (e) {
      return [];
    }
  }
}
