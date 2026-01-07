import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/shared/utils/app_logger.dart';

class UserProfileRemoteDataSource {
  UserProfileRemoteDataSource(this._supabaseClient);

  final SupabaseClient _supabaseClient;
  static const _userProfileTable = 'user_profile';

  Future<Map<String, dynamic>> fetchUserProfile() async {
    try {
      final user = _supabaseClient.auth.currentUser;
      if (user == null) {
        throw '無法獲取使用者資訊，請重新登入';
      }

      final response = await _supabaseClient
          .from(_userProfileTable)
          .select(
            'user_id, name, height, weight, chest, waist, hips, shoulder_width, sleeve_length',
          )
          .eq('user_id', user.id)
          .single();

      return response;
    } catch (e) {
      if (e is String) rethrow;
      AppLogger.error('個人資料獲取失敗', e);
      throw '無法載入個人資料，請檢查網路連線';
    }
  }

  Future<Map<String, dynamic>> updateUserProfile(
    final String userId,
    final Map<String, dynamic> updates,
  ) async {
    try {
      final response = await _supabaseClient
          .from(_userProfileTable)
          .update(updates)
          .eq('user_id', userId)
          .select()
          .single();

      return response;
    } catch (e) {
      AppLogger.error('個人資料更新失敗', e);
      throw '個人資料更新失敗，請稍後再試';
    }
  }
}
