import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/shared/models/body_measurements.dart';
import 'package:tryzeon/shared/models/result.dart';
import 'package:tryzeon/shared/services/cache_service.dart';

class UserProfileService {
  static final _supabase = Supabase.instance.client;
  static const _userProfileTable = 'user_profile';

  // SharedPreferences key
  static const _cacheKey = 'user_profile_cache';

  /// 取得使用者個人資料
  static Future<Result<UserProfile>> getUserProfile({
    final bool forceRefresh = false,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return Result.failure('使用者未登入');
      }

      if (!forceRefresh) {
        final cachedData = await CacheService.loadJSON(_cacheKey);
        if (cachedData != null) {
          final cachedProfile = UserProfile.fromJson(cachedData);
          return Result.success(data: cachedProfile);
        }
      }

      final response = await _supabase
          .from(_userProfileTable)
          .select()
          .eq('user_id', user.id)
          .single();

      await CacheService.saveJSON(_cacheKey, response);

      final profile = UserProfile.fromJson(response);
      return Result.success(data: profile);
    } catch (e) {
      return Result.failure('取得個人資料失敗', error: e);
    }
  }

  /// 更新使用者個人資料
  static Future<Result<UserProfile>> updateUserProfile({
    final String? name,
    final BodyMeasurements? measurements,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return Result.failure('使用者未登入');
      }

      final updateData = <String, dynamic>{};

      if (name != null) updateData['name'] = name.trim();
      if (measurements != null) updateData.addAll(measurements.toJson());

      final response = await _supabase
          .from(_userProfileTable)
          .update(updateData)
          .eq('user_id', user.id)
          .select()
          .single();

      await CacheService.saveJSON(_cacheKey, response);

      final profile = UserProfile.fromJson(response);
      return Result.success(data: profile);
    } catch (e) {
      return Result.failure('更新個人資料失敗', error: e);
    }
  }
}

class UserProfile {
  UserProfile({
    required this.userId,
    required this.name,
    required this.measurements,
  });

  factory UserProfile.fromJson(final Map<String, dynamic> json) {
    return UserProfile(
      userId: json['user_id'] as String,
      name: json['name'] as String,
      measurements: BodyMeasurements.fromJson(json),
    );
  }
  final String userId;
  final String name;
  final BodyMeasurements measurements;

  Map<String, dynamic> toJson() {
    return {'user_id': userId, 'name': name, ...measurements.toJson()};
  }
}
