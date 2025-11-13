import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tryzeon/shared/services/cache_service.dart';

class AvatarService {
  static final _supabase = Supabase.instance.client;
  static const _bucket = 'avatars';

  /// 獲取頭像（優先從本地獲取，本地沒有才從後端拿）
  static Future<AvatarResult> getAvatar() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      return AvatarResult.failure('用戶未登入');
    }

    try {
      // 1. 先從 Supabase 查詢檔案名稱
      final files = await _supabase.storage.from(_bucket).list(path: '$userId/avatar');
      if (files.isEmpty) {
        return AvatarResult.success(null);
      }

      final fileName = '$userId/avatar/${files.first.name}';

      // 2. 檢查本地是否有緩存
      final localFile = await CacheService.getImage(fileName);
      if (localFile != null) {
        return AvatarResult.success(localFile);
      }

      // 3. 本地沒有，從 Supabase 下載
      final bytes = await _supabase.storage.from(_bucket).download(fileName);

      // 創建臨時文件並保存到本地緩存
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/temp_avatar.jpg');
      await tempFile.writeAsBytes(bytes);

      final savedFile = await CacheService.saveImage(tempFile, fileName);
      await tempFile.delete(); // 刪除臨時文件

      return AvatarResult.success(savedFile);
    } catch (e) {
      return AvatarResult.failure('獲取頭像失敗: ${e.toString()}');
    }
  }
  
  /// 上傳頭像（先上傳到後端，成功後才保存到本地）
  static Future<AvatarResult> uploadAvatar(File imageFile) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      return AvatarResult.failure('用戶未登入');
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = '$userId/avatar/$timestamp.jpg';

    try {
      // 1. 先刪除舊頭像（本地和 Supabase）
      await _deleteOldAvatars(userId);

      // 2. 上傳到 Supabase
      final bytes = await imageFile.readAsBytes();
      await _supabase.storage.from(_bucket).uploadBinary(
        fileName,
        bytes,
        fileOptions: const FileOptions(
          contentType: 'image/jpeg',
          upsert: false,
        ),
      );

      // 3. 保存新的頭像到本地
      final savedFile = await CacheService.saveImage(imageFile, fileName);
      return AvatarResult.success(savedFile);
    } catch (e) {
      return AvatarResult.failure('上傳頭像失敗: ${e.toString()}');
    }
  }

  /// 刪除舊頭像（Supabase 和本地）
  static Future<void> _deleteOldAvatars(String userId) async {
    // 刪除 Supabase 中的舊頭像
    final files = await _supabase.storage.from(_bucket).list(path: '$userId/avatar');
    if (files.isNotEmpty) {
      await _supabase.storage.from(_bucket).remove(['$userId/avatar/${files.first.name}']);
    }

    // 刪除本地舊頭像
    await CacheService.deleteImages(relativePath: '$userId/avatar');
  }
}

class AvatarResult {
  final bool success;
  final File? file;
  final String? errorMessage;

  AvatarResult({
    required this.success,
    this.file,
    this.errorMessage,
  });

  factory AvatarResult.success(File? file) {
    return AvatarResult(success: true, file: file);
  }

  factory AvatarResult.failure(String errorMessage) {
    return AvatarResult(success: false, errorMessage: errorMessage);
  }
}