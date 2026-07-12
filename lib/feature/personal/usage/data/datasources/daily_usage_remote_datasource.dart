import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/core/config/app_constants.dart';
import 'package:tryzeon/core/error/exceptions.dart';
import 'package:tryzeon/feature/personal/usage/data/models/daily_usage_model.dart';

class DailyUsageRemoteDataSource {
  DailyUsageRemoteDataSource(this._supabase);
  final SupabaseClient _supabase;
  static const _userDailyUsageTable = AppConstants.tableUserDailyUsage;

  /// Returns an empty model when authenticated but no row exists yet today.
  Future<DailyUsageModel> getTodayUsage() async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw const UnauthenticatedException();

    final today = DateTime.now().toUtc().toIso8601String().substring(0, 10);
    final response = await _supabase
        .from(_userDailyUsageTable)
        .select('user_id, usage_date, tryon_count, chat_count, video_count')
        .eq('user_id', user.id)
        .eq('usage_date', today)
        .maybeSingle();
    if (response == null) {
      return DailyUsageModel.empty(userId: user.id, usageDate: today);
    }
    return DailyUsageModel.fromJson(response);
  }
}
