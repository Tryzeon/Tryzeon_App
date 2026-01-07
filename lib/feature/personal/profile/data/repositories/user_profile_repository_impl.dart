import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/feature/personal/profile/data/datasources/user_profile_local_datasource.dart';
import 'package:tryzeon/feature/personal/profile/data/datasources/user_profile_remote_datasource.dart';
import 'package:tryzeon/feature/personal/profile/data/models/user_profile_model.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/user_profile.dart';
import 'package:tryzeon/feature/personal/profile/domain/repositories/user_profile_repository.dart';
import 'package:typed_result/typed_result.dart';

class UserProfileRepositoryImpl implements UserProfileRepository {
  UserProfileRepositoryImpl({
    required final UserProfileRemoteDataSource remoteDataSource,
    required final UserProfileLocalDataSource localDataSource,
    required final SupabaseClient supabaseClient,
  }) : _remoteDataSource = remoteDataSource,
       _localDataSource = localDataSource,
       _supabaseClient = supabaseClient;

  final UserProfileRemoteDataSource _remoteDataSource;
  final UserProfileLocalDataSource _localDataSource;
  final SupabaseClient _supabaseClient;

  @override
  Future<UserProfile> getUserProfile() async {
    final user = _supabaseClient.auth.currentUser;
    if (user == null) {
      throw '無法獲取使用者資訊，請重新登入';
    }

    final cachedProfile = _localDataSource.getCachedProfile();
    if (cachedProfile != null) {
      return cachedProfile;
    }

    final json = await _remoteDataSource.fetchUserProfile();
    final profile = UserProfileModel.fromJson(json);

    _localDataSource.updateCachedProfile(profile);

    return profile;
  }

  @override
  Future<Result<void, String>> updateUserProfile({
    required final UserProfile original,
    required final UserProfile target,
  }) async {
    try {
      final user = _supabaseClient.auth.currentUser;
      if (user == null) {
        return const Err('無法獲取使用者資訊，請重新登入');
      }

      final updateData = original.getDirtyFields(target);

      if (updateData.isEmpty) {
        return const Ok(null);
      }

      final updatedJson = await _remoteDataSource.updateUserProfile(user.id, updateData);

      final updatedProfile = UserProfileModel.fromJson(updatedJson);

      _localDataSource.updateCachedProfile(updatedProfile);

      return const Ok(null);
    } catch (e) {
      if (e is String) {
        return Err(e);
      }
      return const Err('個人資料更新失敗，請稍後再試');
    }
  }
}
