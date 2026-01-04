import 'dart:io';
import 'dart:typed_data';

import 'package:mime/mime.dart';
import 'package:path/path.dart' as path;
import 'package:supabase_flutter/supabase_flutter.dart';

class AvatarRemoteDataSource {
  AvatarRemoteDataSource(this._supabase);
  final SupabaseClient _supabase;
  static const _bucket = 'avatars';

  /// Get avatar path from user metadata (pure API call)
  Future<String?> fetchAvatarPath() async {
    var user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('無法獲取使用者資訊，請重新登入');
    }

    final response = await _supabase.auth.refreshSession();
    user = response.session?.user ?? user;

    final avatarPath = user.userMetadata?['avatar_path'] as String?;
    return (avatarPath == null || avatarPath.isEmpty) ? null : avatarPath;
  }

  /// Download avatar file from storage (pure download)
  Future<Uint8List> downloadAvatar(final String avatarPath) async {
    return _supabase.storage.from(_bucket).download(avatarPath);
  }

  Future<String> uploadAvatar(final File image) async {
    var user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('無法獲取使用者資訊，請重新登入');
    }

    final response = await _supabase.auth.refreshSession();
    user = response.session?.user ?? user;

    final imageName = path.basename(image.path);
    final avatarPath = '${user.id}/avatar/$imageName';
    final mimeType = lookupMimeType(image.path);

    final bytes = await image.readAsBytes();
    await _supabase.storage
        .from(_bucket)
        .uploadBinary(avatarPath, bytes, fileOptions: FileOptions(contentType: mimeType));

    await _supabase.auth.updateUser(UserAttributes(data: {'avatar_path': avatarPath}));

    return avatarPath;
  }

  Future<void> deleteAvatar(final String avatarPath) async {
    await _supabase.storage.from(_bucket).remove([avatarPath]);
  }
}
