import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/shared/models/result.dart';
import 'package:tryzeon/shared/services/cache_service.dart';

class AvatarService {
  static final _supabase = Supabase.instance.client;
  static const _bucket = 'avatars';

  /// 獲取頭像
  static Future<Result<({String avatarPath, File avatarFile})>> getAvatar({
    final bool forceRefresh = false,
  }) async {
    try {
      var user = _supabase.auth.currentUser;
      if (user == null) {
        return Result.failure('使用者獲取失敗');
      }

      if (forceRefresh) {
        final response = await _supabase.auth.refreshSession();
        user = response.session?.user ?? user;
      }

      final avatarPath = user.userMetadata?['avatar_path'] as String?;
      if (avatarPath == null || avatarPath.isEmpty) {
        return Result.success();
      }

      final cachedAvatar = await CacheService.getImage(avatarPath);
      if (cachedAvatar != null) {
        return Result.success(data: (avatarPath: avatarPath, avatarFile: cachedAvatar));
      }

      // Download from Supabase Storage
      final url = await _supabase.storage.from(_bucket).createSignedUrl(avatarPath, 60);
      final avatar = await CacheService.getImage(avatarPath, downloadUrl: url);

      return Result.success(data: (avatarPath: avatarPath, avatarFile: avatar!));
    } catch (e) {
      return Result.failure('頭像獲取失敗', error: e);
    }
  }

  /// 上傳頭像
  static Future<Result<({String avatarPath, File avatarFile})>> uploadAvatar(
    final File image,
  ) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return Result.failure('使用者獲取失敗');
      }

      // 1. 刪除舊頭像（如果存在）
      final oldAvatarPath = user.userMetadata?['avatar_path'] as String?;
      if (oldAvatarPath != null && oldAvatarPath.isNotEmpty) {
        await _supabase.storage.from(_bucket).remove([oldAvatarPath]);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final avatarPath = '${user.id}/avatar/$timestamp.png';

      // 2. 上傳到 Supabase
      final bytes = await image.readAsBytes();
      await _supabase.storage
          .from(_bucket)
          .uploadBinary(
            avatarPath,
            bytes,
            fileOptions: const FileOptions(contentType: 'image/png'),
          );

      // 3. 更新 Metadata
      await _supabase.auth.updateUser(UserAttributes(data: {'avatar_path': avatarPath}));

      // 4. 保存到本地緩存
      final avatar = await CacheService.saveImage(bytes, avatarPath);

      return Result.success(data: (avatarPath: avatarPath, avatarFile: avatar));
    } catch (e) {
      return Result.failure('頭像上傳失敗', error: e);
    }
  }
}
