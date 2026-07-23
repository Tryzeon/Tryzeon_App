import 'dart:io';

import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/core/config/app_constants.dart';
import 'package:tryzeon/core/error/exceptions.dart';
import 'package:tryzeon/feature/common/body_measurements/data/models/body_measurements_model.dart';
import 'package:tryzeon/feature/personal/profile/data/models/user_profile_model.dart';

class UserProfileRemoteDataSource {
  UserProfileRemoteDataSource(this._supabaseClient);

  final SupabaseClient _supabaseClient;
  static const _userProfileTable = AppConstants.tableUserProfiles;
  static const _avatarBucket = AppConstants.bucketUserAvatars;

  Future<UserProfileModel> getUserProfile() async {
    final user = _supabaseClient.auth.currentUser;
    if (user == null) throw const UnauthenticatedException();

    final response = await _supabaseClient
        .from(_userProfileTable)
        .select(
          'user_id, name, email, avatar_path, measurements, gender, age_range, style_preferences, is_onboarded, created_at, updated_at',
        )
        .eq('user_id', user.id)
        .single();

    return UserProfileModel.fromJson(response);
  }

  Future<UserProfileModel> updateUserBodyMeasurements(
    final BodyMeasurementsModel measurements,
  ) async {
    final user = _supabaseClient.auth.currentUser;
    if (user == null) throw const UnauthenticatedException();

    final response = await _supabaseClient
        .from(_userProfileTable)
        .update({'measurements': measurements.toJson()})
        .eq('user_id', user.id)
        .select()
        .single();

    return UserProfileModel.fromJson(response);
  }

  Future<UserProfileModel> updateUserProfile({
    required final String name,
    final String? gender,
    final String? ageRange,
  }) async {
    final user = _supabaseClient.auth.currentUser;
    if (user == null) throw const UnauthenticatedException();

    final response = await _supabaseClient
        .from(_userProfileTable)
        .update({'name': name, 'gender': gender, 'age_range': ageRange})
        .eq('user_id', user.id)
        .select()
        .single();

    return UserProfileModel.fromJson(response);
  }

  Future<UserProfileModel> updateStylePreferences(
    final List<String> stylePreferences,
  ) async {
    final user = _supabaseClient.auth.currentUser;
    if (user == null) throw const UnauthenticatedException();

    final response = await _supabaseClient
        .from(_userProfileTable)
        .update({'style_preferences': stylePreferences})
        .eq('user_id', user.id)
        .select()
        .single();

    return UserProfileModel.fromJson(response);
  }

  Future<UserProfileModel> completeUserOnboarding({
    final String? gender,
    final String? ageRange,
    final List<String>? stylePreferences,
  }) async {
    final user = _supabaseClient.auth.currentUser;
    if (user == null) throw const UnauthenticatedException();

    final response = await _supabaseClient
        .from(_userProfileTable)
        .update({
          'gender': gender,
          'age_range': ageRange,
          'style_preferences': stylePreferences,
          'is_onboarded': true,
        })
        .eq('user_id', user.id)
        .select()
        .single();

    return UserProfileModel.fromJson(response);
  }

  Future<UserProfileModel> updateUserAvatarPath(final String avatarPath) async {
    final user = _supabaseClient.auth.currentUser;
    if (user == null) throw const UnauthenticatedException();

    final response = await _supabaseClient
        .from(_userProfileTable)
        .update({'avatar_path': avatarPath})
        .eq('user_id', user.id)
        .select()
        .single();

    return UserProfileModel.fromJson(response);
  }

  Future<String> uploadAvatar(final File image) async {
    final user = _supabaseClient.auth.currentUser;
    if (user == null) throw const UnauthenticatedException();

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
    return _supabaseClient.storage
        .from(_avatarBucket)
        .createSignedUrl(avatarPath, AppConstants.signedUrlTtlSeconds);
  }
}
