import 'package:supabase_flutter/supabase_flutter.dart';
import './file_cache_service.dart';

class LogoutService {
  static final _supabase = Supabase.instance.client;

  static Future<void> logout() async {
    final userId = _supabase.auth.currentUser?.id;

    // 清除當前用戶的所有本地緩存
    if (userId != null) {
      await FileCacheService.deleteFolder(userId);
    }

    // 執行 Supabase 登出
    await _supabase.auth.signOut();
  }
}
