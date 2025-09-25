import 'package:supabase_flutter/supabase_flutter.dart';

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

  /// 獲取當前用戶的顯示名稱
  static String? get displayName {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;
    
    // 優先使用 user_metadata 中的 display_name
    final displayName = user.userMetadata?['name'] as String?;
    if (displayName != null && displayName.isNotEmpty) {
      return displayName;
    }
    
    return "無名氏";
  }

  /// 登出
  static Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}