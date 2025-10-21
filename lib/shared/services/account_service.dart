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

  /// 取得顯示名稱
  static String get displayName {
    final user = _supabase.auth.currentUser;
    if (user == null) return "無名氏";

    final name = user.userMetadata?['name'] as String?;
    if (name != null && name.isNotEmpty) {
      return name;
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
    } on AuthException catch (e) {
      return AccountResult.failure(e.message);
    } catch (e) {
      return AccountResult.failure('更新失敗: ${e.toString()}');
    }
  }
}
