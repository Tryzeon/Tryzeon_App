import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tryzeon/shared/services/file_cache_service.dart';

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

  /// Google 登入
  static Future<AuthResult> signInWithGoogle({
    required UserType userType,
  }) async {
    try {
      final success = await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.tryzeon://login-callback',
        authScreenLaunchMode: LaunchMode.externalApplication,
      );

      if (!success) {
        return AuthResult.failure('Google 登入失敗，請稍後再試');
      }

      // 等待認證狀態變化，最多等待 60 秒
      final user = await _supabase.auth.onAuthStateChange
          .firstWhere((state) => state.event == AuthChangeEvent.signedIn)
          .timeout(
            const Duration(seconds: 60),
            onTimeout: () => throw Exception('登入超時'),
          )
          .then((state) => state.session?.user);

      if (user == null) {
        return AuthResult.failure('Google 登入失敗：無法取得用戶資訊');
      }

      // 儲存登入類型
      await saveLastLoginType(userType);

      return AuthResult.success(user);
    } on AuthException catch (e) {
      return AuthResult.failure(e.message);
    } catch (e) {
      return AuthResult.failure('Google 登入失敗：${e.toString()}');
    }
  }

  /// Facebook 登入
  static Future<AuthResult> signInWithFacebook({
    required UserType userType,
  }) async {
    try {
      final success = await _supabase.auth.signInWithOAuth(
        OAuthProvider.facebook,
        redirectTo: 'io.supabase.tryzeon://login-callback',
        authScreenLaunchMode: LaunchMode.externalApplication,
      );

      if (!success) {
        return AuthResult.failure('Facebook 登入失敗，請稍後再試');
      }

      // 等待認證狀態變化，最多等待 60 秒
      final user = await _supabase.auth.onAuthStateChange
          .firstWhere((state) => state.event == AuthChangeEvent.signedIn)
          .timeout(
            const Duration(seconds: 60),
            onTimeout: () => throw Exception('登入超時'),
          )
          .then((state) => state.session?.user);

      if (user == null) {
        return AuthResult.failure('Facebook 登入失敗：無法取得用戶資訊');
      }

      // 儲存登入類型
      await saveLastLoginType(userType);

      return AuthResult.success(user);
    } on AuthException catch (e) {
      return AuthResult.failure(e.message);
    } catch (e) {
      return AuthResult.failure('Facebook 登入失敗：${e.toString()}');
    }
  }

  /// 切換帳號類型
  static Future<AuthResult> switchUserType(UserType targetType) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return AuthResult.failure('未登入');
      }

      // 儲存切換後的登入類型
      await saveLastLoginType(targetType);

      return AuthResult.success(user);
    } catch (e) {
      return AuthResult.failure('切換失敗，請稍後再試');
    }
  }

  /// 登出
  static Future<void> signOut() async {
    final userId = _supabase.auth.currentUser?.id;

    // 清除當前用戶的所有本地緩存
    if (userId != null) {
      await FileCacheService.deleteFolder(userId);
    }

    // 清除 SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastLoginTypeKey);

    // 執行 Supabase 登出
    await _supabase.auth.signOut();
  }
}