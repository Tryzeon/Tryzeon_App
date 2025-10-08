import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tryzeon/shared/services/file_cache_service.dart';

class AvatarService {
  static final _supabase = Supabase.instance.client;
  static const _bucket = 'avatars';

  /// 上傳頭像（先上傳到後端，成功後才保存到本地）
  static Future<String?> uploadAvatar(File imageFile) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final storageFileName = '$userId/avatar/avatar.jpg';
    final localFileName = '$userId/avatar/avatar_$timestamp.jpg';

    try {
      // 1. 先上傳到 Supabase
      final bytes = await imageFile.readAsBytes();
      await _supabase.storage.from(_bucket).uploadBinary(
        storageFileName,
        bytes,
        fileOptions: const FileOptions(
          contentType: 'image/jpeg',
          upsert: true,
        ),
      );

      // 2. 保存新的頭像到本地
      final savedFile = await FileCacheService.saveFile(imageFile, localFileName);
      return savedFile.path;
    } catch (e) {
      // 上傳失敗，拋出錯誤讓上層處理
      rethrow;
    }
  }

  /// 獲取頭像（優先從本地獲取，本地沒有才從後端拿）
  static Future<String?> getAvatar() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;
    
    final fileName = '$userId/avatar/avatar.jpg';

    try {
      // 1. 先檢查本地資料夾是否有緩存
      final localFiles = await FileCacheService.getFiles(
        relativePath: '$userId/avatar',
        filePattern: 'avatar',
      );
      final avatarFile = localFiles.firstOrNull;

      if (avatarFile != null) {
        return avatarFile.path;
      }

      // 2. 本地沒有，從 Supabase 下載
      final bytes = await _supabase.storage.from(_bucket).download(fileName);

      // 創建臨時文件並保存到本地緩存
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/temp_avatar.jpg');
      await tempFile.writeAsBytes(bytes);

      final savedFile = await FileCacheService.saveFile(tempFile, fileName);
      await tempFile.delete(); // 刪除臨時文件

      return savedFile.path;
    } catch (e) {
      return null;
    }
  }
}