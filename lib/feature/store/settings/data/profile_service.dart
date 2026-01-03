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
        storageDeserializer: (final json) => StoreProfile.fromJson(json),
      ),
    );
  }

  /// 獲取店家資料 (Internal Fetcher)
  static Future<StoreProfile?> fetchStoreProfile() async {
    try {
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
    } catch (e) {
      if (e is String) rethrow;
      AppLogger.error('店家資料獲取失敗', e);
      throw '無法載入店家資料，請檢查網路連線';
    }
  }

  /// 獲取店家名稱
  static Future<String> getStoreName() async {
    final state = await storeProfileQuery().fetch();
    return state.data?.name ?? '店家';
  }

  /// 更新店家資料
  static Future<Result<void, String>> updateStoreProfile({
    required final StoreProfile original,
    required final StoreProfile target,
    final File? logo,
  }) async {
    try {
      final store = _supabase.auth.currentUser;
      if (store == null) {
        return const Err('無法獲取使用者資訊，請重新登入');
      }

      StoreProfile finalTarget = target;
      if (logo != null) {
        final newLogoPath = await _uploadLogo(store, logo);
        finalTarget = target.copyWith(logoPath: newLogoPath);
      }

      // 3. 取得變更欄位
      final updateData = original.getDirtyFields(finalTarget);

      // 如果沒有任何變更，直接返回
      if (updateData.isEmpty) {
        return const Ok(null);
      }

      final response = await _supabase
          .from(_storesProfileTable)
          .update(updateData)
          .eq('store_id', store.id)
          .select()
          .single();

      // 成功上傳新圖並更新 DB 後，才非同步清理舊圖
      if (logo != null && original.logoPath != null && original.logoPath!.isNotEmpty) {
        _deleteLogo(original.logoPath!).ignore();
      }

      final updatedProfile = StoreProfile.fromJson(response);

      // 直接更新本地快取
      CachedQuery.instance.updateQuery(
        key: ['store_profile', store.id],
        updateFn: (final dynamic old) => updatedProfile,
      );

      return const Ok(null);
    } catch (e) {
      AppLogger.error('店家資料更新失敗', e);
      return const Err('店家資料更新失敗，請稍後再試');
    }
  }

  /// 獲取店家 Logo
  static Future<Result<File, String>> _getLogo(final String logoPath) async {
    try {
      // Supabase getPublicUrl 是同步操作，開銷極低
      // 且因為是 Public URL，其 URL 對於相同路徑是固定的，CacheManager 內部可有效處理緩存
      final url = _supabase.storage.from(_logoBucket).getPublicUrl(logoPath);

      // 交由 CacheService (CacheManager) 處理緩存邏輯：有緩存讀緩存，無緩存則下載
      final logo = await CacheService.getImage(logoPath, downloadUrl: url);

      if (logo == null) {
        return const Err('無法獲取 Logo 圖片，請稍後再試');
      }

      return Ok(logo);
    } catch (e) {
      AppLogger.error('Logo獲取失敗', e);
      return const Err('無法載入店家 Logo ，請稍後再試');
    }
  }

  static Future<String> _uploadLogo(final User store, final File image) async {
    try {
      final imageName = p.basename(image.path);
      final logoPath = '${store.id}/logo/$imageName';

      final mimeType = lookupMimeType(image.path);

      // 上傳到 Storage (先上傳，確保成功)
      final bytes = await image.readAsBytes();
      await _supabase.storage
          .from(_logoBucket)
          .uploadBinary(logoPath, bytes, fileOptions: FileOptions(contentType: mimeType));

      // 保存圖片到本地緩存 (樂觀更新)
      await CacheService.saveImage(bytes, logoPath);

      return logoPath;
    } catch (e) {
      AppLogger.error('Logo 上傳失敗', e);
      rethrow;
    }
  }

  /// 刪除舊 Logo (清理操作)
  static Future<void> _deleteLogo(final String logoPath) async {
    try {
      await _supabase.storage.from(_logoBucket).remove([logoPath]);
      // 同步清理本地舊緩存
      await CacheService.deleteImage(logoPath);
    } catch (e) {
      // 僅記錄錯誤，不中斷流程
      AppLogger.error('Logo 刪除失敗: $logoPath', e);
    }
  }
}

class StoreProfile {
  StoreProfile({required this.storeId, required this.name, this.address, this.logoPath});

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
  final String? address;
  final String? logoPath;

  /// 按需載入 Logo，使用快取機制
  Future<Result<File?, String>> loadLogo() async {
    if (logoPath == null || logoPath!.isEmpty) {
      return const Ok(null);
    }
    return StoreProfileService._getLogo(logoPath!);
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
