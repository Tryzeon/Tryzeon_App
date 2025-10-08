import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/shared/services/logout_service.dart';

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

  static String get displayName {
    final user = _supabase.auth.currentUser;
    if (user == null) return "無名氏";

    final displayName = user.userMetadata?['username'] as String?;
    if (displayName != null && displayName.isNotEmpty) {
      return displayName;
    }
    
    return "無名氏";
  }

  /// 更新使用者名稱
  static Future<AuthResult> updateUserName(String name) async {
    try {
      final response = await _supabase.auth.updateUser(
        UserAttributes(
          data: {'username': name.trim()},
        ),
      );

      if (response.user != null) {
        return AuthResult.success(response.user!);
      } else {
        return AuthResult.failure('更新失敗');
      }
    } catch (e) {
      return AuthResult.failure('更新失敗: $e');
    }
  }

  /// 登出
  static Future<void> signOut() async {
    await LogoutService.logout();
  }
}