import 'dart:io';

import 'package:cached_query_flutter/cached_query_flutter.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/shared/services/cache_service.dart';
import 'package:tryzeon/shared/utils/app_logger.dart';
import 'package:typed_result/typed_result.dart';

class StoreProfileService {
  static final _supabase = Supabase.instance.client;
  static const _storesProfileTable = 'store_profile';
  static const _logoBucket = 'store';

  /// 獲取店家資料 Query
  static Query<StoreProfile?> storeProfileQuery() {
    final store = _supabase.auth.currentUser;
    final id = store?.id;

    return Query<StoreProfile?>(
      key: ['store_profile', id],
      queryFn: fetchStoreProfile,
      config: QueryConfig(
        storageDeserializer: (final dynamic json) {
          if (json == null) return null;
          return StoreProfile.fromJson(json);
        },
      ),
    );
  }

  /// 獲取店家資料 (Internal Fetcher)
  static Future<StoreProfile?> fetchStoreProfile() async {
    final store = _supabase.auth.currentUser;
    if (store == null) {
      throw '無法獲取使用者資訊，請重新登入';
    }

    final response = await _supabase
        .from(_storesProfileTable)
        .select('store_id, name, address, logo_path')
        .eq('store_id', store.id)
        .maybeSingle();

    if (response == null) {
      return null;
    }
    return StoreProfile.fromJson(response);
  }

  /// 獲取店家名稱
  static Future<String> getStoreName() async {
    final state = await storeProfileQuery().fetch();
    return state.data?.name ?? '店家';
  }

  /// 更新店家資料
  static Future<Result<void, String>> updateStoreProfile({
    required final StoreProfile target,
    final File? logo,
  }) async {
    try {
      final store = _supabase.auth.currentUser;
      if (store == null) {
        return const Err('無法獲取使用者資訊，請重新登入');
      }

      // 1. 取得目前資料以進行比對
      final currentProfileState = await storeProfileQuery().fetch();
      if (currentProfileState.error != null) {
        return const Err('資料同步錯誤，請重新刷新頁面');
      }
      final original = currentProfileState.data;

      if (original == null) {
        // Should not happen if store exists, but handle creation logic if needed or error
        return const Err('無法找到店家資料');
      }

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
        return const Ok(null);
      }

      await _supabase
          .from(_storesProfileTable)
          .update(updateData)
          .eq('store_id', store.id);

      CachedQuery.instance.invalidateCache(key: ['store_profile', store.id]);

      return const Ok(null);
    } catch (e) {
      AppLogger.error('店家資料更新失敗', e);
      return const Err('店家資料更新失敗，請稍後再試');
    }
  }

  /// 獲取店家 Logo
  static Future<Result<File?, String>> _getLogo() async {
    try {
      final state = await storeProfileQuery().fetch();
      if (state.error != null) {
        return Err(state.error!);
      }

      final logoPath = state.data?.logoPath;
      if (logoPath == null || logoPath.isEmpty) {
        return const Ok(null);
      }

      final cachedLogo = await CacheService.getImage(logoPath);
      if (cachedLogo != null) {
        return Ok(cachedLogo);
      }

      // Download from Supabase Storage
      final url = _supabase.storage.from(_logoBucket).getPublicUrl(logoPath);

      final logo = await CacheService.getImage(logoPath, downloadUrl: url);

      return Ok(logo);
    } catch (e) {
      AppLogger.error('Logo獲取失敗', e);
      return const Err('無法載入店家 Logo ，請稍後再試');
    }
  }

  /// 上傳店家 Logo 到 Storage 並返回路徑
  static Future<String> _uploadLogo(final User store, final File image) async {
    // 1. 刪除舊 Logo
    final state = await storeProfileQuery().fetch();
    final oldLogoPath = state.data?.logoPath;
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
  Future<Result<File?, String>> loadLogo() async {
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
