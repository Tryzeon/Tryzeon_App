import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/shared/services/cache_service.dart';

class StoreProfileService {
  static final _supabase = Supabase.instance.client;
  static const _storesProfileTable = 'store_profile';
  static const _logoBucket = 'store';

  // SharedPreferences key
  static const _cachedKey = 'store_profile_cache';

  /// 獲取店家資料
  static Future<StoreProfileResult> getStoreProfile({bool forceRefresh = false}) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return StoreProfileResult.failure('使用者未登入');
      }

      // 讀取 cache
      if (!forceRefresh) {
        final cachedData = await CacheService.loadJSON(_cachedKey);
        if (cachedData != null) {
          final cachedProfile = StoreProfile.fromJson(cachedData);
          return StoreProfileResult.success(cachedProfile);
        }
      }

      // 從後端抓取資料
      final response = await _supabase
          .from(_storesProfileTable)
          .select()
          .eq('store_id', user.id)
          .maybeSingle();

      if (response == null) {
        return StoreProfileResult.failure('查無店家資料');
      }

      await CacheService.saveJSON(_cachedKey, response);

      final profile = StoreProfile.fromJson(response);
      return StoreProfileResult.success(profile);
    } catch (e) {
      return StoreProfileResult.failure('取得店家資料失敗: ${e.toString()}');
    }
  }

  /// 獲取店家名稱
  static Future<String> getStoreName({bool forceRefresh = false}) async {
    final result = await getStoreProfile(forceRefresh: forceRefresh);
    return result.profile?.storeName ?? '店家';
  }
  
  /// 更新店家資料
  static Future<StoreProfileResult> updateStoreProfile({
    required String storeName,
    required String address,
  }) async {
    try {
      final user = _supabase.auth.currentUser?.id;
      if (user == null) {
        return StoreProfileResult.failure('使用者未登入');
      }

      final data = {
        'store_id': user,
        'store_name': storeName,
        'address': address,
      };

      final response = await _supabase
          .from(_storesProfileTable)
          .upsert(data, onConflict: 'store_id')
          .select()
          .single();

      await CacheService.saveJSON(_cachedKey, response);

      final profile = StoreProfile.fromJson(response);
      return StoreProfileResult.success(profile);
    } catch (e) {
      return StoreProfileResult.failure('更新店家資料失敗: ${e.toString()}');
    }
  }

  /// 載入 Logo（優先從本地獲取，本地沒有才從後端拿）
  static Future<File?> loadLogo(String storeId) async {
    // 1. 先檢查本地資料夾是否有緩存
    final localFiles = await CacheService.getImages(
      relativePath: '$storeId/logo',
    );

    if (localFiles.isNotEmpty) {
      return localFiles.first;
    }

    // 2. 本地沒有，從 Supabase 下載
    final files = await _supabase.storage.from(_logoBucket).list(path: '$storeId/logo');
    if (files.isEmpty) {
      return null;
    }

    final fileName = '$storeId/logo/${files.first.name}';
    final bytes = await _supabase.storage.from(_logoBucket).download(fileName);

    // 保存到本地緩存
    final savedFile = await CacheService.saveImage(bytes, fileName);

    return savedFile;
  }
  
  /// 上傳店家Logo（先上傳到後端，成功後才保存到本地）
  static Future<void> uploadLogo(File logo) async {
    final user = _supabase.auth.currentUser?.id;
    if (user == null) {
      throw Exception('使用者未登入');
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = '$user/logo/$timestamp.jpg';

    // 1. 先刪除舊 Logo（本地和 Supabase）
    await _deleteLogo(user);

    // 2. 上傳到 Supabase
    final bytes = await logo.readAsBytes();
    await _supabase.storage.from(_logoBucket).uploadBinary(
      fileName,
      bytes,
      fileOptions: const FileOptions(
        contentType: 'image/jpeg',
        upsert: false,
      ),
    );

    // 3. 保存新的 Logo 到本地
    await CacheService.saveImage(bytes, fileName);
  }

  /// 刪除舊 Logo（Supabase 和本地）
  static Future<void> _deleteLogo(String user) async {
    try {
      // 刪除 Supabase 中的舊 Logo
      final files = await _supabase.storage.from(_logoBucket).list(path: '$user/logo');
      if (files.isNotEmpty) {
        await _supabase.storage.from(_logoBucket).remove(['$user/logo/${files.first.name}']);
      }

      // 刪除本地舊 Logo
      await CacheService.deleteImages(relativePath: '$user/logo');
    } catch (e) {
      // 忽略刪除錯誤
    }
  }
}

class StoreProfile {
  final String storeId;
  final String storeName;
  final String address;

  StoreProfile({
    required this.storeId,
    required this.storeName,
    required this.address,
  });

  /// 按需載入 Logo，使用快取機制
  Future<File?> loadLogo() async {
    return StoreProfileService.loadLogo(storeId);
  }

  factory StoreProfile.fromJson(Map<String, dynamic> json) {
    return StoreProfile(
      storeId: json['store_id'],
      storeName: json['store_name'],
      address: json['address'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'store_id': storeId,
      'store_name': storeName,
      'address': address,
    };
  }
}

class StoreProfileResult {
  final bool success;
  final StoreProfile? profile;
  final String? errorMessage;

  StoreProfileResult({
    required this.success,
    this.profile,
    this.errorMessage,
  });

  factory StoreProfileResult.success(StoreProfile profile) {
    return StoreProfileResult(success: true, profile: profile);
  }

  factory StoreProfileResult.failure(String errorMessage) {
    return StoreProfileResult(success: false, errorMessage: errorMessage);
  }
}