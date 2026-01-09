import 'dart:io';

import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';

class UserProfileRemoteDataSource {
  UserProfileRemoteDataSource(this._supabaseClient);

  final SupabaseClient _supabaseClient;
  static const _table = 'user_profile';
  static const _avatarBucket = 'avatars';

  Future<Map<String, dynamic>> fetchUserProfile() async {
    final user = _supabaseClient.auth.currentUser;
    if (user == null) throw '無法獲取使用者資訊，請重新登入';

    final response = await _supabaseClient
        .from(_table)
        .select(
          'user_id, name, avatar_path, height, weight, chest, waist, hips, shoulder_width, sleeve_length',
        )
        .eq('user_id', user.id)
        .single();

    return response;
  }

  Future<Map<String, dynamic>> updateUserProfile(
    final Map<String, dynamic> updates,
  ) async {
    final user = _supabaseClient.auth.currentUser;
    if (user == null) throw '無法獲取使用者資訊，請重新登入';

    final response = await _supabaseClient
        .from(_table)
        .update(updates)
        .eq('user_id', user.id)
        .select()
        .single();

    return response;
  }

  Future<String> uploadAvatar(final File image) async {
    final user = _supabaseClient.auth.currentUser;
    if (user == null) throw '無法獲取使用者資訊，請重新登入';

    final imageName = p.basename(image.path);
    final avatarPath = '${user.id}/avatar/$imageName';
    final mimeType = lookupMimeType(image.path);

    final bytes = await image.readAsBytes();
    await _supabaseClient.storage
        .from(_avatarBucket)
        .uploadBinary(avatarPath, bytes, fileOptions: FileOptions(contentType: mimeType));

    return avatarPath;
  }

  Future<void> deleteAvatar(final String avatarPath) async {
    await _supabaseClient.storage.from(_avatarBucket).remove([avatarPath]);
  }

  Future<String> createSignedUrl(final String avatarPath) async {
    return _supabaseClient.storage.from(_avatarBucket).createSignedUrl(avatarPath, 3600);
  }

  String getAvatarPublicUrl(final String avatarPath) {
    return _supabaseClient.storage.from(_avatarBucket).getPublicUrl(avatarPath);
  }
}
