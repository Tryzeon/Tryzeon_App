import 'package:supabase_flutter/supabase_flutter.dart';

class AccountResult {
  final bool success;
  final User? user;
  final String? errorMessage;

  AccountResult({
    required this.success,
    this.user,
    this.errorMessage,
  });

  factory AccountResult.success(User user) {
    return AccountResult(success: true, user: user);
  }

  factory AccountResult.failure(String errorMessage) {
    return AccountResult(success: false, errorMessage: errorMessage);
  }
}

class AccountService {
  static final _supabase = Supabase.instance.client;

  static String get displayName {
    final user = _supabase.auth.currentUser;
    if (user == null) return "無名氏";

    final displayName = user.userMetadata?['name'] as String?;
    if (displayName != null && displayName.isNotEmpty) {
      return displayName;
    }

    return "無名氏";
  }

  /// 更新使用者名稱
  static Future<AccountResult> updateUserName(String name) async {
    try {
      final response = await _supabase.auth.updateUser(
        UserAttributes(
          data: {'name': name.trim()},
        ),
      );

      if (response.user != null) {
        return AccountResult.success(response.user!);
      } else {
        return AccountResult.failure('更新失敗');
      }
    } catch (e) {
      return AccountResult.failure('更新失敗: $e');
    }
  }
}