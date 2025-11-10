import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';

class ProductTypeService {
  static final _supabase = Supabase.instance.client;
  static const _typesTable = 'product_types';
  static const _cacheKey = 'cached_product_types';
  static const _cacheTimestampKey = 'cached_product_types_timestamp';
  static const _cacheDuration = Duration(days: 7);

  static Future<List<String>> getProductTypesList() async {
    final cached = await _getCachedTypes();
    if (cached != null) return cached;

    final response = await _supabase
        .from(_typesTable)
        .select('name_zh')
        .order('order', ascending: true);

    final List<String> types = [];
    for (final item in response as List) {
      types.add(item['name_zh'] as String);
    }

    if (types.isNotEmpty) {
      await _cacheTypes(types);
    }

    return types;
  }

  /// 從快取讀取
  static Future<List<String>?> _getCachedTypes() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(_cacheTimestampKey);

    if (timestamp != null) {
      final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      if (DateTime.now().difference(cacheTime) > _cacheDuration) {
        await _clearCache();
        return null;
      }
    }

    final cachedJson = prefs.getString(_cacheKey);
    if (cachedJson != null) {
      final decoded = json.decode(cachedJson);
      return List<String>.from(decoded);
    }

    return null;
  }

  /// 儲存到快取
  static Future<void> _cacheTypes(List<String> types) async {
    final prefs = await SharedPreferences.getInstance();
    final encodedTypes = json.encode(types);
    await prefs.setString(_cacheKey, encodedTypes);
    await prefs.setInt(_cacheTimestampKey, DateTime.now().millisecondsSinceEpoch);
  }

  /// 清除快取
  static Future<void> _clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKey);
    await prefs.remove(_cacheTimestampKey);
  }
}
