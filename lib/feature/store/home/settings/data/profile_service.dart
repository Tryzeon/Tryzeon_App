import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tryzeon/shared/services/file_cache_service.dart';

class StoreProfileService {
  static final _supabase = Supabase.instance.client;
  static const _storesTable = 'store_profile';
  static const _logoBucket = 'store';

  /// 獲取店家資料
  static Future<StoreData?> getStore() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    try {
      final response = await _supabase
          .from(_storesTable)
          .select()
          .eq('store_id', userId)
          .maybeSingle();

      if (response == null) return null;
      return StoreData.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  /// 獲取店家名稱
  static Future<String> getStoreName() async {
    final storeData = await getStore();
    return storeData?.storeName ?? '店家';
  }
  
  /// 更新店家資料
  static Future<bool> upsertStore({
    required String storeName,
    required String address,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return false;

    try {
      final data = {
        'store_id': userId,
        'store_name': storeName,
        'address': address,
      };

      await _supabase
          .from(_storesTable)
          .upsert(data, onConflict: 'store_id');

      return true;
    } catch (e) {
      return false;
    }
  }

  /// 獲取 Logo（優先從本地獲取，本地沒有才從後端拿）
  static Future<File?> getLogo() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    try {
      // 1. 先檢查本地資料夾是否有緩存
      final localFiles = await FileCacheService.getFiles(
        relativePath: '$userId/logo',
      );

      if (localFiles.isNotEmpty) {
        return localFiles.first;
      }

      // 2. 本地沒有，從 Supabase 下載
      final files = await _supabase.storage.from(_logoBucket).list(path: '$userId/logo');
      if (files.isEmpty) return null;

      final fileName = '$userId/logo/${files.first.name}';
      final bytes = await _supabase.storage.from(_logoBucket).download(fileName);

      // 創建臨時文件並保存到本地緩存
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/temp_logo.jpg');
      await tempFile.writeAsBytes(bytes);

      final savedFile = await FileCacheService.saveFile(tempFile, fileName);
      await tempFile.delete(); // 刪除臨時文件

      return savedFile;
    } catch (e) {
      return null;
    }
  }
  
  /// 上傳店家Logo（先上傳到後端，成功後才保存到本地）
  static Future<String?> uploadLogo(File logoFile) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = '$userId/logo/$timestamp.jpg';

    try {
      // 1. 先刪除舊 Logo（本地和 Supabase）
      await _deleteOldLogos(userId);

      // 2. 上傳到 Supabase
      final bytes = await logoFile.readAsBytes();
      await _supabase.storage.from(_logoBucket).uploadBinary(
        fileName,
        bytes,
        fileOptions: const FileOptions(
          contentType: 'image/jpeg',
          upsert: false,
        ),
      );

      // 3. 保存新的 Logo 到本地
      final savedFile = await FileCacheService.saveFile(logoFile, fileName);
      return savedFile.path;
    } catch (e) {
      // 上傳失敗，拋出錯誤讓上層處理
      rethrow;
    }
  }

  /// 刪除舊 Logo（Supabase 和本地）
  static Future<void> _deleteOldLogos(String userId) async {
    try {
      // 刪除 Supabase 中的舊 Logo
      final files = await _supabase.storage.from(_logoBucket).list(path: '$userId/logo');
      if (files.isNotEmpty) {
        await _supabase.storage.from(_logoBucket).remove(['$userId/logo/${files.first.name}']);
      }

      // 刪除本地舊 Logo
      await FileCacheService.deleteFiles(relativePath: '$userId/logo');
    } catch (e) {
      // 忽略刪除錯誤
    }
  }
}

class StoreData {
  final String storeId;
  final String storeName;
  final String address;

  StoreData({
    required this.storeId,
    required this.storeName,
    required this.address,
  });

  factory StoreData.fromJson(Map<String, dynamic> json) {
    return StoreData(
      storeId: json['store_id'],
      storeName: json['store_name'],
      address: json['address'],
    );
  }
}