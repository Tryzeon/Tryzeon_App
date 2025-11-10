import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';

class ProductTypeService {
  static final _supabase = Supabase.instance.client;
  static const _typesTable = 'product_types';
  static const _cacheKey = 'cached_product_types';
  static const _cacheTimestampKey = 'cached_product_types_timestamp';
  static const _cacheDuration = Duration(days: 7);

  /// 獲取所有商品類型
  static Future<Map<String, String>> getProductTypes() async {
    final cached = await _getCachedTypes();
    if (cached != null) return cached;

    final response = await _supabase
        .from(_typesTable)
        .select('name_zh, name_en')
        .order('order', ascending: true);

    final Map<String, String> types = {};
    for (final item in response as List) {
      types[item['name_zh']] = item['name_en'];
    }

    if (types.isNotEmpty) {
      await _cacheTypes(types);
    }

    return types;
  }

  /// 獲取所有商品類型（中文名稱列表）
  static Future<List<String>> getProductTypesList() async {
    final types = await getProductTypes();
    return types.keys.toList();
  }

  /// 根據中文名稱獲取英文代碼
  static Future<String> getEnglishCode(String nameZh) async {
    final types = await getProductTypes();
    return types[nameZh] ?? nameZh;
  }

  /// 根據英文代碼獲取中文名稱
  static Future<String> getChineseName(String nameEn) async {
    final types = await getProductTypes();
    final entry = types.entries.where((e) => e.value == nameEn).firstOrNull;
    return entry?.key ?? nameEn;
  }

  /// 從快取讀取
  static Future<Map<String, String>?> _getCachedTypes() async {
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
      return Map<String, String>.from(decoded);
    }

    return null;
  }

  /// 儲存到快取
  static Future<void> _cacheTypes(Map<String, String> types) async {
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
