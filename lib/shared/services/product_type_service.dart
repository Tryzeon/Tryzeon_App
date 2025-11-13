import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/shared/services/cache_service.dart';

class ProductTypeService {
  static final _supabase = Supabase.instance.client;
  static const _typesTable = 'product_types';

  static const _cacheKey = 'product_types_cache';

  static Future<ProductTypeResult> getProductTypesList({bool forceRefresh = false}) async {
    try {
      if (!forceRefresh) {
        final cachedData = await CacheService.loadList(_cacheKey);
        if (cachedData != null) {
          final types = List<String>.from(cachedData);
          return ProductTypeResult.success(types);
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

      return ProductTypeResult.success(types);
    } catch (e) {
      return ProductTypeResult.failure('取得商品類型失敗: ${e.toString()}');
    }
  }
}

class ProductTypeResult {
  final bool success;
  final List<String>? types;
  final String? errorMessage;

  ProductTypeResult({
    required this.success,
    this.types,
    this.errorMessage,
  });

  factory ProductTypeResult.success(List<String> types) {
    return ProductTypeResult(success: true, types: types);
  }

  factory ProductTypeResult.failure(String errorMessage) {
    return ProductTypeResult(success: false, errorMessage: errorMessage);
  }
}