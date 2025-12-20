import 'package:cached_query_flutter/cached_query_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/shared/models/body_measurements.dart';
import 'package:tryzeon/shared/utils/app_logger.dart';
import 'package:typed_result/typed_result.dart';

class UserProfileService {
  static final _supabase = Supabase.instance.client;
  static const _userProfileTable = 'user_profile';

  /// 取得使用者個人資料
  static Future<Result<UserProfile, String>> getUserProfile({
    final bool forceRefresh = false,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return const Err('無法獲取使用者資訊，請重新登入');
      }

      final query = Query<UserProfile>(
        key: ['user_profile', user.id],

        queryFn: () async {
          final response = await _supabase
              .from(_userProfileTable)
              .select(
                'user_id, name, height, weight, chest, waist, hips, shoulder_width, sleeve_length',
              )
              .eq('user_id', user.id)
              .single();

          return UserProfile.fromJson(response);
        },
      );

      final state = forceRefresh ? await query.refetch() : await query.fetch();

      if (state.error != null) {
        AppLogger.error('個人資料取得失敗', state.error);
        return const Err('無法取得個人資料，請稍後再試');
      }

      return Ok(state.data!);
    } catch (e) {
      AppLogger.error('個人資料取得失敗', e);
      return const Err('無法取得個人資料，請稍後再試');
    }
  }

  /// 更新使用者個人資料
  static Future<Result<void, String>> updateUserProfile({
    required final UserProfile target,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return const Err('無法獲取使用者資訊，請重新登入');
      }

      // 1. 取得目前資料以進行比對
      final currentProfileResult = await getUserProfile();
      if (!currentProfileResult.isSuccess) {
        AppLogger.error('無法取得目前資料以進行更新比對: ${currentProfileResult.getError()}');
        return const Err('資料同步錯誤，請重新刷新頁面');
      }
      final original = currentProfileResult.get()!;

      // 2. 取得變更欄位 (直接比對傳入的 target 與 original)
      final updateData = original.getDirtyFields(target);

      // 如果沒有變更，直接返回原資料
      if (updateData.isEmpty) {
        return const Ok(null);
      }

      await _supabase.from(_userProfileTable).update(updateData).eq('user_id', user.id);

      // 更新 Cache
      CachedQuery.instance.updateQuery(
        key: ['user_profile', user.id],

        updateFn: (final dynamic old) => target,
      );

      return const Ok(null);
    } catch (e) {
      AppLogger.error('個人資料更新失敗', e);
      return const Err('個人資料更新失敗，請稍後再試');
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
