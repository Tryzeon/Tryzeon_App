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
        final cachedData = await CacheService.loadJSON(_cachedKey);
        if (cachedData != null) {
          final cachedStoreProfile = StoreProfile.fromJson(cachedData);
          return Result.success(data: cachedStoreProfile);
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
    final File? logo,
  }) async {
    try {
      final store = _supabase.auth.currentUser;
      if (store == null) {
        return Result.failure('使用者獲取失敗');
      }

      final Map<String, dynamic> data = {
        'store_id': store.id,
        'name': name,
        'address': address,
      };

      if (logo != null) {
        final logoPath = await _uploadLogo(store, logo);
        data['logo_path'] = logoPath;
      }

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

  /// 獲取店家 Logo
  static Future<Result<File>> _getLogo({final bool forceRefresh = false}) async {
    try {
      final storeProfile = await getStoreProfile(forceRefresh: forceRefresh);
      if (!storeProfile.isSuccess) {
        return Result.failure(storeProfile.errorMessage!);
      }

      final logoPath = storeProfile.data?.logoPath;
      if (logoPath == null || logoPath.isEmpty) {
        return Result.success();
      }

      final cachedLogo = await CacheService.getImage(logoPath);
      if (cachedLogo != null) {
        return Result.success(data: cachedLogo);
      }

      // Download from Supabase Storage
      final url = await _supabase.storage.from(_logoBucket).createSignedUrl(logoPath, 60);

      final logo = await CacheService.getImage(logoPath, downloadUrl: url);

      return Result.success(data: logo);
    } catch (e) {
      return Result.failure('Logo獲取失敗', error: e);
    }
  }

  /// 上傳店家 Logo 到 Storage 並返回路徑
  static Future<String> _uploadLogo(
    final User store,
    final File image,
  ) async {
    // 1. 刪除舊 Logo
    final storeProfile = await getStoreProfile();
    final oldLogoPath = storeProfile.data?.logoPath;
    if (oldLogoPath != null && oldLogoPath.isNotEmpty) {
      await _supabase.storage.from(_logoBucket).remove([oldLogoPath]);
    }
    
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final logoPath = '${store.id}/logo/$timestamp.png';

    // 2. 上傳到 Storage
    final bytes = await image.readAsBytes();
    await _supabase.storage
        .from(_logoBucket)
        .uploadBinary(
          logoPath,
          bytes,
          fileOptions: const FileOptions(contentType: 'image/png'),
        );

    // 3. 保存圖片到本地緩存
    await CacheService.saveImage(bytes, logoPath);

    return logoPath;
  }
}

class StoreProfile {
  StoreProfile({
    required this.storeId,
    required this.name,
    required this.address,
    this.logoPath,
  });

  factory StoreProfile.fromJson(final Map<String, dynamic> json) {
    return StoreProfile(
      storeId: json['store_id'],
      name: json['name'],
      address: json['address'],
      logoPath: json['logo_path'],
    );
  }

  final String storeId;
  final String name;
  final String address;
  final String? logoPath;

  /// 按需載入 Logo，使用快取機制
  Future<Result<File>> loadLogo() async {
    return StoreProfileService._getLogo();
  }

  Map<String, dynamic> toJson() {
    return {'store_id': storeId, 'name': name, 'address': address, 'logo_path': logoPath};
  }
}
