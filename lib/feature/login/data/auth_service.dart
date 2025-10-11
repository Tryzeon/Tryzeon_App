import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  /// 註冊新用戶
  static Future<AuthResult> signUp({
    required String email,
    required String password,
    required UserType userType,
    String? name,
  }) async {
    try {
      // 先檢查用戶是否已存在
      final existingUser = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      if (existingUser.user != null) {
        // 用戶已存在，添加新的用戶類型
        final existingMetadata = existingUser.user!.userMetadata ?? {};
        
        // 檢查是否已有此類型
        if (existingMetadata[userType.name] == true) {
          return AuthResult.failure(
            userType == UserType.personal 
              ? '此帳號已經是個人用戶' 
              : '此帳號已經是店家用戶'
          );
        }
        
        // 添加新的用戶類型
        await _supabase.auth.updateUser(
          UserAttributes(
            data: {
              ...existingMetadata,
              userType.name: true,
              if (name != null && existingMetadata['name'] == null) 'name': name,
            },
          ),
        );
        
        return AuthResult.success(existingUser.user!);
      }
    } catch (e) {
      // 登入失敗，表示用戶不存在，繼續註冊新用戶
    }

    try {
      // 註冊新用戶
      final metadata = {
        userType.name: true,
        'username': name
      };

      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: metadata,
      );

      if (response.user != null) {
        return AuthResult.success(response.user!);
      }
      
      return AuthResult.failure('註冊失敗，請稍後再試');
    } on AuthException catch (e) {
      return AuthResult.failure(e.message);
    } catch (e) {
      return AuthResult.failure('註冊失敗，請稍後再試');
    }
  }

  /// 登入用戶並驗證用戶類型
  static Future<AuthResult> signInWithPassword({
    required String email,
    required String password,
    required UserType expectedUserType,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        return AuthResult.failure('登入失敗');
      }

      // 檢查用戶類型
      final userMetadata = response.user!.userMetadata;
      final hasExpectedUserType = userMetadata?[expectedUserType.name] == true;
      
      if (!hasExpectedUserType) {
        // 用戶類型不符，登出
        return AuthResult.failure(
          expectedUserType == UserType.personal
              ? '此帳號不是個人用戶帳號'
              : '此帳號不是店家帳號',
        );
      }
      
      // 儲存最後登入的類型
      await saveLastLoginType(expectedUserType);

      return AuthResult.success(response.user!);
    } on AuthException catch (e) {
      return AuthResult.failure(e.message);
    } catch (e) {
      return AuthResult.failure('登入失敗，請稍後再試');
    }
  }

  /// Google 登入
  static Future<AuthResult> signInWithGoogle({
    required UserType userType,
  }) async {
    try {
      const iosClientId = '186632123893-jbfo2s7ubp3r14luahjiuu3fvi21fler.apps.googleusercontent.com';

      final googleSignIn = GoogleSignIn(
        clientId: iosClientId,
      );

      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        return AuthResult.failure('登入失敗');
      }

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;

      if (idToken == null) {
        throw AuthException('無法取得 Google ID Token');
      }

      final response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: googleAuth.accessToken,
      );

      if (response.user == null) {
        return AuthResult.failure('Google 登入失敗: user not found');
      }

      // 儲存最後登入的類型
      await saveLastLoginType(userType);

      // 獲取現有的 metadata
      final existingMetadata = response.user!.userMetadata ?? {};

      // 檢查是否已有此類型
      if (existingMetadata[userType.name] == true) {
        // 已經有此類型，直接返回成功
        return AuthResult.success(response.user!);
      }else{
        // 添加新的用戶類型
        final displayName = existingMetadata['name'];

        await _supabase.auth.updateUser(
          UserAttributes(
            data: {
              ...existingMetadata,
              userType.name: true,
              "username": displayName,
            },
          ),
        );

        return AuthResult.success(response.user!);
      }
    } on AuthException catch (e) {
      return AuthResult.failure(e.message);
    } catch (e) {
      return AuthResult.failure('Google 登入失敗：${e.toString()}');
    }
  }

  /// 檢查當前用戶是否有指定類型的帳號
  static Future<bool> hasUserType(UserType userType) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      final userMetadata = user.userMetadata;
      return userMetadata?[userType.name] == true;
    } catch (e) {
      return false;
    }
  }

  /// 切換帳號類型（需要檢查是否有該類型的帳號）
  static Future<AuthResult> switchUserType(UserType targetType) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return AuthResult.failure('未登入');
      }

      // 檢查是否有目標類型的帳號
      final hasType = await hasUserType(targetType);
      if (!hasType) {
        return AuthResult.failure(
          targetType == UserType.personal
              ? '您還沒有個人帳號'
              : '您還沒有店家帳號'
        );
      }

      // 儲存切換後的登入類型
      await saveLastLoginType(targetType);

      return AuthResult.success(user);
    } catch (e) {
      return AuthResult.failure('切換失敗，請稍後再試');
    }
  }
}