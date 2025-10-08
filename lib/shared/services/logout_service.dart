import 'package:supabase_flutter/supabase_flutter.dart';
import '../../feature/personal/home/data/avatar_service.dart';

class LogoutService {
  static final _supabase = Supabase.instance.client;

  static Future<void> logout() async {
    // 清除本地緩存
    await AvatarService.clearLocalCache();

    // 執行 Supabase 登出
    await _supabase.auth.signOut();
  }
}
