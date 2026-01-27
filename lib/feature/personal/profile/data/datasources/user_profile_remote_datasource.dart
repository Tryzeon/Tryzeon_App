import 'dart:io';

import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/core/config/app_constants.dart';
import 'package:tryzeon/feature/personal/profile/data/models/user_profile_model.dart';

class UserProfileRemoteDataSource {
  UserProfileRemoteDataSource(this._supabaseClient);

  final SupabaseClient _supabaseClient;
  static const _table = AppConstants.tableUserProfile;
  static const _avatarBucket = AppConstants.bucketAvatars;

  Future<UserProfileModel> fetchUserProfile() async {
    final user = _supabaseClient.auth.currentUser;
    if (user == null) throw '無法獲取使用者資訊，請重新登入';

    final response = await _supabaseClient
        .from(_table)
        .select(
          'user_id, name, avatar_path, height, chest, waist, hips, shoulder, sleeve, created_at, updated_at',
        )
        .eq('user_id', user.id)
        .single();

    return UserProfileModel.fromJson(response);
  }

  Future<UserProfileModel> updateUserProfile(final UserProfileModel profile) async {
    final user = _supabaseClient.auth.currentUser;
    if (user == null) throw '無法獲取使用者資訊，請重新登入';

    final json = profile.toJson()
      ..remove('user_id')
      ..remove('created_at')
      ..remove('updated_at');

    final response = await _supabaseClient
        .from(_table)
        .update(json)
        .eq('user_id', user.id)
        .select()
        .single();

    return UserProfileModel.fromJson(response);
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
}
