import 'dart:io';

import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/shared/models/result.dart';
import 'package:tryzeon/shared/services/cache_service.dart';
import 'package:tryzeon/shared/utils/app_logger.dart';

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
        return Result.failure('無法獲取使用者資訊，請重新登入');
      }

      // 讀取 cache
      if (!forceRefresh) {
        final cachedData = await CacheService.loadFromCache(_cachedKey);
        if (cachedData != null) {
          final cachedStoreProfile = StoreProfile.fromJson(
            Map<String, dynamic>.from(cachedData as Map),
          );
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

      await CacheService.saveToCache(_cachedKey, response);

      final storeProfile = StoreProfile.fromJson(response);
      return Result.success(data: storeProfile);
    } catch (e) {
      AppLogger.error('店家資料取得失敗', e);
      return Result.failure('無法取得店家資料，請稍後再試');
    }
  }

  /// 獲取店家名稱
  static Future<String> getStoreName({final bool forceRefresh = false}) async {
    final response = await getStoreProfile(forceRefresh: forceRefresh);
    return response.data?.name ?? '店家';
  }

  /// 更新店家資料
  static Future<Result<StoreProfile>> updateStoreProfile({
    required final StoreProfile target,
    final File? logo,
  }) async {
    try {
      final store = _supabase.auth.currentUser;
      if (store == null) {
        return Result.failure('無法獲取使用者資訊，請重新登入');
      }

      // 1. 取得目前資料以進行比對
      final currentProfileResult = await getStoreProfile();
      if (!currentProfileResult.isSuccess) {
        AppLogger.error('無法取得目前資料以進行更新比對: ${currentProfileResult.errorMessage}');
        return Result.failure('資料同步錯誤，請重新刷新頁面');
      }
      final original = currentProfileResult.data!;

      // 2. 處理 Logo 上傳 (這裡會更新 target 的 logoPath)
      StoreProfile finalTarget = target;
      if (logo != null) {
        final newLogoPath = await _uploadLogo(store, logo);
        finalTarget = target.copyWith(logoPath: newLogoPath);
      }

      // 3. 取得變更欄位
      final updateData = original.getDirtyFields(finalTarget);

      // 如果沒有變更，直接返回原資料
      if (updateData.isEmpty) {
        return Result.success(data: original);
      }

      final response = await _supabase
          .from(_storesProfileTable)
          .update(updateData)
          .eq('store_id', store.id)
          .select()
          .single();

      await CacheService.saveToCache(_cachedKey, response);

      final storeProfile = StoreProfile.fromJson(response);
      return Result.success(data: storeProfile);
    } catch (e) {
      AppLogger.error('店家資料更新失敗', e);
      return Result.failure('店家資料更新失敗，請稍後再試');
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
      final url = _supabase.storage.from(_logoBucket).getPublicUrl(logoPath);

      final logo = await CacheService.getImage(logoPath, downloadUrl: url);

      return Result.success(data: logo);
    } catch (e) {
      AppLogger.error('Logo獲取失敗', e);
      return Result.failure('無法載入店家 Logo ，請稍後再試');
    }
  }

  /// 上傳店家 Logo 到 Storage 並返回路徑
  static Future<String> _uploadLogo(final User store, final File image) async {
    // 1. 刪除舊 Logo
    final storeProfile = await getStoreProfile();
    final oldLogoPath = storeProfile.data?.logoPath;
    if (oldLogoPath != null && oldLogoPath.isNotEmpty) {
      await _supabase.storage.from(_logoBucket).remove([oldLogoPath]);
    }

    final imageName = p.basename(image.path);
    final logoPath = '${store.id}/logo/$imageName';

    final mimeType = lookupMimeType(image.path);

    // 2. 上傳到 Storage
    final bytes = await image.readAsBytes();
    await _supabase.storage
        .from(_logoBucket)
        .uploadBinary(logoPath, bytes, fileOptions: FileOptions(contentType: mimeType));

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

  StoreProfile copyWith({
    final String? storeId,
    final String? name,
    final String? address,
    final String? logoPath,
  }) {
    return StoreProfile(
      storeId: storeId ?? this.storeId,
      name: name ?? this.name,
      address: address ?? this.address,
      logoPath: logoPath ?? this.logoPath,
    );
  }

  /// 比對另一個 StoreProfile，回傳差異的 Map
  Map<String, dynamic> getDirtyFields(final StoreProfile target) {
    final updates = <String, dynamic>{};

    if (name != target.name) {
      updates['name'] = target.name;
    }

    if (address != target.address) {
      updates['address'] = target.address;
    }

    if (logoPath != target.logoPath) {
      updates['logo_path'] = target.logoPath;
    }

    return updates;
  }
}
