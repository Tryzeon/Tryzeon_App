import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tryzeon/shared/services/cache_service.dart';

enum UserType { personal, store }

class AuthResult {
  final bool success;
  final User? user;
  final String? errorMessage;

  AuthResult({
    required this.success,
    this.user,
    this.errorMessage,
  });

  factory AuthResult.success(User user) {
    return AuthResult(success: true, user: user);
  }

  factory AuthResult.failure(String errorMessage) {
    return AuthResult(success: false, errorMessage: errorMessage);
  }
}

class AuthService {
  static final _supabase = Supabase.instance.client;
  static const _lastLoginTypeKey = 'last_login_type';

  /// 儲存最後登入的類型
  static Future<void> saveLastLoginType(UserType userType) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastLoginTypeKey, userType.name);
  }

  /// 取得最後登入的類型
  static Future<UserType?> getLastLoginType() async {
    final prefs = await SharedPreferences.getInstance();
    final typeString = prefs.getString(_lastLoginTypeKey);
    if (typeString == null) return null;

    return UserType.values.firstWhere(
      (type) => type.name == typeString,
      orElse: () => UserType.personal,
    );
  }

  /// 通用第三方登入
  static Future<AuthResult> signInWithProvider({
    required String provider,
    required UserType userType,
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
          return AuthResult.failure('不支援的登入方式：$provider');
      }

      final success = await _supabase.auth.signInWithOAuth(
        oauthProvider,
        redirectTo: 'io.supabase.tryzeon://login-callback',
        authScreenLaunchMode: LaunchMode.externalApplication,
      );

      if (!success) {
        return AuthResult.failure('$provider 登入失敗，請稍後再試');
      }

      // 等待認證狀態變化
      final user = await _supabase.auth.onAuthStateChange
          .firstWhere((state) => state.event == AuthChangeEvent.signedIn)
          .then((state) => state.session?.user);

      if (user == null) {
        return AuthResult.failure('$provider 登入失敗：無法取得用戶資訊');
      }

      // 儲存登入類型
      await saveLastLoginType(userType);

      return AuthResult.success(user);
    } on AuthException catch (e) {
      return AuthResult.failure(e.message);
    } catch (e) {
      return AuthResult.failure('$provider 登入失敗：${e.toString()}');
    }
  }

  /// 登出
  static Future<void> signOut() async {
    final userId = _supabase.auth.currentUser?.id;

    // 清除當前用戶的所有本地緩存
    if (userId != null) {
      await CacheService.deleteFolder(userId);
    }

    // 清除所有 SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    // 執行 Supabase 登出
    await _supabase.auth.signOut();
  }
}