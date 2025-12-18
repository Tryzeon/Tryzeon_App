import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/shared/services/cache_service.dart';
import 'package:tryzeon/shared/utils/app_logger.dart';
import 'package:typed_result/typed_result.dart';

enum UserType { personal, store }

class AuthService {
  static final _supabase = Supabase.instance.client;
  static const _lastLoginTypeKey = 'last_login_type';

  /// 儲存最後登入的類型
  static Future<void> setLastLoginType(final UserType userType) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastLoginTypeKey, userType.name);
  }

  /// 取得最後登入的類型
  static Future<UserType?> getLastLoginType() async {
    final prefs = await SharedPreferences.getInstance();
    final typeString = prefs.getString(_lastLoginTypeKey);
    if (typeString == null) return null;

    return UserType.values.firstWhere(
      (final type) => type.name == typeString,
      orElse: () => UserType.personal,
    );
  }

  /// 通用第三方登入
  static Future<Result<void, String>> signInWithProvider({
    required final String provider,
    required final UserType userType,
  }) async {
    try {
      // 根據 provider 選擇對應的 OAuth Provider
      final OAuthProvider oauthProvider;
      switch (provider.toLowerCase()) {
        case 'google':
          oauthProvider = OAuthProvider.google;
          break;
        case 'facebook':
          oauthProvider = OAuthProvider.facebook;
          break;
        case 'apple':
          oauthProvider = OAuthProvider.apple;
          break;
        default:
          return Err('目前不支援 $provider 登入');
      }

      final success = await _supabase.auth.signInWithOAuth(
        oauthProvider,
        redirectTo: 'io.supabase.tryzeon://login-callback',
        authScreenLaunchMode: LaunchMode.externalApplication,
      );

      if (!success) {
        return Err('$provider 登入失敗，請稍後再試');
      }

      // 等待認證狀態變化
      final user = await _supabase.auth.onAuthStateChange
          .firstWhere((final state) => state.event == AuthChangeEvent.signedIn)
          .then((final state) => state.session?.user);

      if (user == null) {
        return Err('$provider 登入失敗，無法取得用戶資訊，請稍後再試');
      }

      // 儲存登入類型
      await setLastLoginType(userType);

      return const Ok(null);
    } catch (e) {
      AppLogger.error('$provider 登入失敗', e);
      return Err('$provider 登入失敗，請稍後再試');
    }
  }

  /// 登出
  static Future<Result<void, String>> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      AppLogger.error('Supabase 登出失敗 (已忽略)', e);
    }

    try {
      await CacheService.clearCache();
    } catch (e) {
      AppLogger.error('清除快取失敗 (已忽略)', e);
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (e) {
      AppLogger.error('清除登入類型失敗 (已忽略)', e);
    }

    return const Ok(null);
  }
}
