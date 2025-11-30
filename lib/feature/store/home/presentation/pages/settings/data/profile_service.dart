import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/shared/models/result.dart';
import 'package:tryzeon/shared/services/cache_service.dart';

class StoreProfileService {
  static final _supabase = Supabase.instance.client;
  static const _storesProfileTable = 'store_profile';
  static const _logoBucket = 'store';

  // SharedPreferences key
  static const _cachedKey = 'store_profile_cache';

  /// 獲取店家資料
  static Future<Result<StoreProfile>> getStoreProfile({
    final bool forceRefresh = false,
  }) async {
    try {
      final store = _supabase.auth.currentUser;
      if (store == null) {
        return Result.failure('使用者獲取失敗');
      }

      // 讀取 cache
      if (!forceRefresh) {
        final cachedStoreProfile = await CacheService.loadJSON(_cachedKey);
        if (cachedStoreProfile != null) {
          final storeProfile = StoreProfile.fromJson(cachedStoreProfile);
          return Result.success(data: storeProfile);
        }
      }

      // 從後端抓取資料
      final response = await _supabase
          .from(_storesProfileTable)
          .select()
          .eq('store_id', store.id)
          .maybeSingle();

      if (response == null) {
        return Result.success();
      }

      await CacheService.saveJSON(_cachedKey, response);

      final storeProfile = StoreProfile.fromJson(response);
      return Result.success(data: storeProfile);
    } catch (e) {
      return Result.failure('店家資料取得失敗', error: e);
    }
  }

  /// 獲取店家名稱
  static Future<String> getStoreName({final bool forceRefresh = false}) async {
    final response = await getStoreProfile(forceRefresh: forceRefresh);
    return response.data?.name ?? '店家';
  }

  /// 更新店家資料
  static Future<Result<StoreProfile>> updateStoreProfile({
    required final String name,
    required final String address,
  }) async {
    try {
      final store = _supabase.auth.currentUser;
      if (store == null) {
        return Result.failure('使用者獲取失敗');
      }

      final data = {'store_id': store.id, 'name': name, 'address': address};

      final response = await _supabase
          .from(_storesProfileTable)
          .update(data)
          .eq('store_id', store.id)
          .select()
          .single();

      await CacheService.saveJSON(_cachedKey, response);

      final storeProfile = StoreProfile.fromJson(response);
      return Result.success(data: storeProfile);
    } catch (e) {
      return Result.failure('店家資料更新失敗', error: e);
    }
  }

  /// 載入 Logo（優先從本地獲取，本地沒有才從後端拿）
  static Future<Result<File>> loadLogo(final String storeId) async {
    try {
      // 1. 先檢查本地資料夾是否有緩存
      final cachedLogo = await CacheService.getImages(relativePath: '$storeId/logo');

      if (cachedLogo.isNotEmpty) {
        return Result.success(data: cachedLogo.first);
      }

      // 2. 本地沒有，從 Supabase 下載
      final logoFiles = await _supabase.storage
          .from(_logoBucket)
          .list(path: '$storeId/logo');

      if (logoFiles.isEmpty) {
        return Result.success();
      }

      final logoPath = '$storeId/logo/${logoFiles.first.name}';
      final bytes = await _supabase.storage.from(_logoBucket).download(logoPath);

      // 保存到本地緩存
      final logo = await CacheService.saveImage(bytes, logoPath);

      return Result.success(data: logo);
    } catch (e) {
      return Result.failure('Logo載入失敗', error: e);
    }
  }

  /// 上傳店家Logo（先上傳到後端，成功後才保存到本地）
  static Future<Result<File>> uploadLogo(final File image) async {
    try {
      final store = _supabase.auth.currentUser;
      if (store == null) {
        return Result.failure('使用者獲取失敗');
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final logoPath = '${store.id}/logo/$timestamp.jpg';

      // 1. 先刪除舊 Logo（本地和 Supabase）
      await _deleteLogo(store.id);

      // 2. 上傳到 Supabase
      final bytes = await image.readAsBytes();
      await _supabase.storage
          .from(_logoBucket)
          .uploadBinary(
            logoPath,
            bytes,
            fileOptions: const FileOptions(contentType: 'image/jpeg'),
          );

      // 3. 保存新的 Logo 到本地
      final logo = await CacheService.saveImage(bytes, logoPath);

      return Result.success(data: logo);
    } catch (e) {
      return Result.failure('Logo上傳失敗', error: e);
    }
  }

  /// 刪除舊 Logo（Supabase 和本地）
  static Future<void> _deleteLogo(final String storeId) async {
    try {
      // 刪除 Supabase 中的舊 Logo
      final logoFiles = await _supabase.storage
          .from(_logoBucket)
          .list(path: '$storeId/logo');

      if (logoFiles.isNotEmpty) {
        await _supabase.storage.from(_logoBucket).remove([
          '$storeId/logo/${logoFiles.first.name}',
        ]);
      }

      // 刪除本地舊 Logo
      await CacheService.deleteImages(relativePath: '$storeId/logo');
    } catch (e) {
      // 忽略刪除錯誤
    }
  }
}

class StoreProfile {
  StoreProfile({required this.storeId, required this.name, required this.address});

  factory StoreProfile.fromJson(final Map<String, dynamic> json) {
    return StoreProfile(
      storeId: json['store_id'],
      name: json['name'],
      address: json['address'],
    );
  }

  final String storeId;
  final String name;
  final String address;

  /// 按需載入 Logo，使用快取機制
  Future<Result<File>> loadLogo() async {
    return StoreProfileService.loadLogo(storeId);
  }

  Map<String, dynamic> toJson() {
    return {'store_id': storeId, 'name': name, 'address': address};
  }
}
