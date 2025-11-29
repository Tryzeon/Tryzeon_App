import 'dart:io';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/shared/models/result.dart';

class AvatarService {
  static final _supabase = Supabase.instance.client;
  static const _bucket = 'avatars';

  /// 獲取頭像
  static Future<Result<File>> getAvatar({
    final bool forceRefresh = false,
  }) async {
    try {
      var user = _supabase.auth.currentUser;
      if (user == null) {
        return Result.failure('請重新登入');
      }

      if (forceRefresh) {
        final response = await _supabase.auth.refreshSession();
        user = response.session?.user ?? user;
      }

      final avatarImage = user.userMetadata?['avatar_path'] as String?;
      if (avatarImage == null || avatarImage.isEmpty) {
        return Result.success();
      }

      final cachedAvatar = await DefaultCacheManager().getFileFromCache(
        avatarImage,
      );
      if (cachedAvatar != null) {
        return Result.success(data: cachedAvatar.file);
      }

      // Download from Supabase Storage
      final url = await _supabase.storage
          .from(_bucket)
          .createSignedUrl(avatarImage, 60);

      final file = await DefaultCacheManager().getSingleFile(
        url,
        key: avatarImage,
      );

      return Result.success(data: file);
    } catch (e) {
      return Result.failure('獲取頭像失敗', error: e);
    }
  }

  /// 上傳頭像
  static Future<Result<File>> uploadAvatar(final File imageFile) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return Result.failure('請重新登入');
      }

      // 1. 刪除舊頭像（如果存在）
      final oldavatarImage = user.userMetadata?['avatar_path'] as String?;
      if (oldavatarImage != null && oldavatarImage.isNotEmpty) {
        await _supabase.storage.from(_bucket).remove([oldavatarImage]);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final avatarImage = '${user.id}/avatar/$timestamp.png';

      // 2. 上傳到 Supabase
      final bytes = await imageFile.readAsBytes();
      await _supabase.storage
          .from(_bucket)
          .uploadBinary(
            avatarImage,
            bytes,
            fileOptions: const FileOptions(contentType: 'image/png'),
          );

      // 3. 更新 Metadata
      await _supabase.auth.updateUser(
        UserAttributes(data: {'avatar_path': avatarImage}),
      );

      // 4. 保存到本地緩存
      final file = await DefaultCacheManager().putFile(
        avatarImage,
        bytes,
        key: avatarImage,
        fileExtension: 'png',
      );

      return Result.success(data: file);
    } catch (e) {
      return Result.failure('上傳頭像失敗', error: e);
    }
  }
}
