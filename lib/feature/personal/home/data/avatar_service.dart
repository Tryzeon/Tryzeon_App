import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tryzeon/shared/services/file_cache_service.dart';

class AvatarService {
  static final _supabase = Supabase.instance.client;
  static const _bucket = 'avatars';

  /// 獲取本地緩存的頭像文件路徑
  static Future<File?> _getLocalAvatarFile() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    return FileCacheService.getFile(
      relativePath: 'avatars/$userId',
      filePattern: 'avatar_',
    );
  }

  /// 保存頭像到本地緩存
  static Future<File> _saveAvatarToLocal(File imageFile) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not logged in');

    // 使用時間戳記作為檔名
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = 'avatar_$timestamp.jpg';

    return FileCacheService.saveFile(
      sourceFile: imageFile,
      relativePath: 'avatars/$userId',
      fileName: fileName,
      deleteOldFiles: true,
      filePattern: 'avatar_',
    );
  }

  /// 從本地緩存刪除頭像
  static Future<void> _deleteLocalAvatar() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    await FileCacheService.deleteFiles(
      relativePath: 'avatars/$userId',
      filePattern: 'avatar_',
    );
  }

  /// 上傳頭像（先上傳到後端，成功後才保存到本地）
  static Future<String?> uploadAvatar(File imageFile) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    try {
      // 1. 先上傳到 Supabase
      final fileName = '$userId/avatar.jpg';
      final bytes = await imageFile.readAsBytes();

      await _supabase.storage.from(_bucket).uploadBinary(
        fileName,
        bytes,
        fileOptions: const FileOptions(
          contentType: 'image/jpeg',
          upsert: true,
        ),
      );

      // 2. 保存新的頭像到本地
      final localFile = await _saveAvatarToLocal(imageFile);
      return localFile.path;
    } catch (e) {
      // 上傳失敗，拋出錯誤讓上層處理
      rethrow;
    }
  }

  /// 獲取頭像（優先從本地獲取，本地沒有才從後端拿）
  static Future<String?> getAvatar() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    // 1. 先檢查本地是否有緩存
    final localFile = await _getLocalAvatarFile();
    if (localFile != null) {
      return localFile.path;
    }

    // 2. 本地沒有，從 Supabase 下載
    try {
      final files = await _supabase.storage.from(_bucket).list(path: userId);

      if (files.isEmpty) return null;

      final fileName = '$userId/avatar.jpg';
      final bytes = await _supabase.storage.from(_bucket).download(fileName);

      // 創建臨時文件並使用 _saveAvatarToLocal 保存
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/temp_avatar.jpg');
      await tempFile.writeAsBytes(bytes);

      final savedFile = await _saveAvatarToLocal(tempFile);
      await tempFile.delete(); // 刪除臨時文件

      return savedFile.path;
    } catch (e) {
      return null;
    }
  }

  /// 清除本地緩存（用於登出時）
  static Future<void> clearLocalCache() async {
    await _deleteLocalAvatar();
  }
}