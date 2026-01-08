import 'dart:io';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/core/services/cache_service.dart';

class AvatarLocalDataSource {
  AvatarLocalDataSource(this._supabase);

  final SupabaseClient _supabase;

  String? getAvatarPath() {
    final user = _supabase.auth.currentUser;
    final avatarPath = user?.userMetadata?['avatar_path'] as String?;
    return (avatarPath == null || avatarPath.isEmpty) ? null : avatarPath;
  }

  Future<File?> getAvatar(final String avatarPath) async {
    return CacheService.getImage(avatarPath);
  }

  Future<void> saveAvatar({
    required final String avatarPath,
    required final File avatarFile,
  }) async {
    final bytes = await avatarFile.readAsBytes();
    await CacheService.saveImage(bytes, avatarPath);
  }

  Future<void> saveAvatarBytes({
    required final String avatarPath,
    required final Uint8List avatarBytes,
  }) async {
    await CacheService.saveImage(avatarBytes, avatarPath);
  }

  Future<void> deleteAvatar(final String avatarPath) async {
    await CacheService.deleteImage(avatarPath);
  }
}
