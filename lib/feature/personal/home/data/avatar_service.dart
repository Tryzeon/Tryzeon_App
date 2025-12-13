import 'dart:io';

import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/shared/services/cache_service.dart';
import 'package:tryzeon/shared/utils/app_logger.dart';
import 'package:typed_result/typed_result.dart';

class AvatarService {
  static final _supabase = Supabase.instance.client;
  static const _bucket = 'avatars';

  /// 獲取頭像
  static Future<Result<({String avatarPath, File avatarFile})?, String>> getAvatar({
    final bool forceRefresh = false,
  }) async {
    try {
      var user = _supabase.auth.currentUser;
      if (user == null) {
        return const Err('無法獲取使用者資訊，請重新登入');
      }

      if (forceRefresh) {
        final response = await _supabase.auth.refreshSession();
        user = response.session?.user ?? user;
      }

      final avatarPath = user.userMetadata?['avatar_path'] as String?;
      if (avatarPath == null || avatarPath.isEmpty) {
        return const Ok(null);
      }

      final cachedAvatar = await CacheService.getImage(avatarPath);
      if (cachedAvatar != null) {
        return Ok((avatarPath: avatarPath, avatarFile: cachedAvatar));
      }

      // Download from Supabase Storage
      final url = await _supabase.storage.from(_bucket).createSignedUrl(avatarPath, 60);
      final avatar = await CacheService.getImage(avatarPath, downloadUrl: url);

      return Ok((avatarPath: avatarPath, avatarFile: avatar!));
    } catch (e) {
      AppLogger.error('頭像獲取失敗', e);
      return const Err('無法取得頭像，請稍後再試');
    }
  }

  /// 上傳頭像
  static Future<Result<({String avatarPath, File avatarFile})?, String>> uploadAvatar(
    final File image,
  ) async {
    try {
      var user = _supabase.auth.currentUser;
      if (user == null) {
        return const Err('無法獲取使用者資訊，請重新登入');
      }

      final response = await _supabase.auth.refreshSession();
      user = response.session?.user ?? user;

      // 1. 刪除舊頭像（如果存在）
      final oldAvatarPath = user.userMetadata?['avatar_path'] as String?;
      if (oldAvatarPath != null && oldAvatarPath.isNotEmpty) {
        await _supabase.storage.from(_bucket).remove([oldAvatarPath]);
      }

      final imageName = p.basename(image.path);
      final avatarPath = '${user.id}/avatar/$imageName';

      final mimeType = lookupMimeType(image.path);

      // 2. 上傳到 Supabase
      final bytes = await image.readAsBytes();
      await _supabase.storage
          .from(_bucket)
          .uploadBinary(
            avatarPath,
            bytes,
            fileOptions: FileOptions(contentType: mimeType),
          );

      // 3. 更新 Metadata
      await _supabase.auth.updateUser(UserAttributes(data: {'avatar_path': avatarPath}));

      // 4. 保存到本地緩存
      final avatar = await CacheService.saveImage(bytes, avatarPath);

      return Ok((avatarPath: avatarPath, avatarFile: avatar));
    } catch (e) {
      AppLogger.error('頭像上傳失敗', e);
      return const Err('頭像上傳失敗，請稍後再試');
    }
  }
}
