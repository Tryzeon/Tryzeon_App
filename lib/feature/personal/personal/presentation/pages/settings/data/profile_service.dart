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
        return Result.failure('使用者獲取失敗');
      }

      if (!forceRefresh) {
        final cachedData = await CacheService.loadFromCache(_cacheKey);
        if (cachedData != null) {
          final cachedUserProfile = UserProfile.fromJson(
            Map<String, dynamic>.from(cachedData as Map),
          );
          return Result.success(data: cachedUserProfile);
        }
      }

      final response = await _supabase
          .from(_userProfileTable)
          .select()
          .eq('user_id', user.id)
          .single();

      await CacheService.saveToCache(_cacheKey, response);

      final userProfile = UserProfile.fromJson(response);
      return Result.success(data: userProfile);
    } catch (e) {
      return Result.failure('個人資料取得失敗', error: e);
    }
  }

  /// 更新使用者個人資料
  static Future<Result<UserProfile>> updateUserProfile({
    required final UserProfile target,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return Result.failure('使用者獲取失敗');
      }

      // 1. 取得目前資料以進行比對
      final currentProfileResult = await getUserProfile();
      if (!currentProfileResult.isSuccess) {
        return Result.failure(
          '無法取得目前資料以進行更新比對',
          errorMessage: currentProfileResult.errorMessage,
        );
      }
      final original = currentProfileResult.data!;

      // 2. 取得變更欄位 (直接比對傳入的 target 與 original)
      final updateData = original.getDirtyFields(target);

      // 如果沒有變更，直接返回原資料
      if (updateData.isEmpty) {
        return Result.success(data: original);
      }

      final response = await _supabase
          .from(_userProfileTable)
          .update(updateData)
          .eq('user_id', user.id)
          .select()
          .single();

      await CacheService.saveToCache(_cacheKey, response);

      final userProfile = UserProfile.fromJson(response);
      return Result.success(data: userProfile);
    } catch (e) {
      return Result.failure('個人資料更新失敗', error: e);
    }
  }
}

class UserProfile {
  UserProfile({required this.userId, required this.name, required this.measurements});

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

  UserProfile copyWith({
    final String? userId,
    final String? name,
    final BodyMeasurements? measurements,
  }) {
    return UserProfile(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      measurements: measurements ?? this.measurements,
    );
  }

  /// 比對另一個 UserProfile，回傳差異的 Map
  Map<String, dynamic> getDirtyFields(final UserProfile target) {
    final updates = <String, dynamic>{};

    if (name != target.name) {
      updates['name'] = target.name;
    }

    updates.addAll(measurements.getDirtyFields(target.measurements));

    return updates;
  }
}
