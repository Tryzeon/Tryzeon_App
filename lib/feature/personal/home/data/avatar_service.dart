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

      final cachedAvatar = await DefaultCacheManager().getFileFromCache(
        avatarPath,
      );
      if (cachedAvatar != null) {
        return Result.success(data: cachedAvatar.file);
      }

      // Download from Supabase Storage
      final url = await _supabase.storage
          .from(_bucket)
          .createSignedUrl(avatarPath, 60);

      final avatar = await DefaultCacheManager().getSingleFile(
        url,
        key: avatarPath,
      );

      return Result.success(data: avatar);
    } catch (e) {
      return Result.failure('頭像獲取失敗', error: e);
    }
  }

  /// 上傳頭像
  static Future<Result<File>> uploadAvatar(final File newAvatar) async {
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
      final bytes = await newAvatar.readAsBytes();
      await _supabase.storage
          .from(_bucket)
          .uploadBinary(
            avatarPath,
            bytes,
            fileOptions: const FileOptions(contentType: 'image/png'),
          );

      // 3. 更新 Metadata
      await _supabase.auth.updateUser(
        UserAttributes(data: {'avatar_path': avatarPath}),
      );

      // 4. 保存到本地緩存
      final avatar = await DefaultCacheManager().putFile(
        avatarPath,
        bytes,
        key: avatarPath,
        fileExtension: 'png',
      );

      return Result.success(data: avatar);
    } catch (e) {
      return Result.failure('頭像上傳失敗', error: e);
    }
  }
}
