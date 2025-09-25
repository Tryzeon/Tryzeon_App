import 'package:google_sign_in/google_sign_in.dart';
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
  static Future<AuthResult> signIn({
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
        await _supabase.auth.signOut();
        return AuthResult.failure(
          expectedUserType == UserType.personal
              ? '此帳號不是個人用戶帳號'
              : '此帳號不是店家帳號',
        );
      }

      return AuthResult.success(response.user!);
    } on AuthException catch (e) {
      return AuthResult.failure(e.message);
    } catch (e) {
      return AuthResult.failure('登入失敗，請稍後再試');
    }
  }

  /// 登出
  static Future<void> signOut() async {
    await _supabase.auth.signOut();
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

      // 獲取現有的 metadata
      final existingMetadata = response.user!.userMetadata ?? {};
      
      // 檢查是否已有此類型
      if (existingMetadata[userType.name] == true) {
        // 已經有此類型，直接返回成功
        return AuthResult.success(response.user!);
      }
      
      final displayName = existingMetadata['name'];

      // 添加新的用戶類型
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
    } on AuthException catch (e) {
      return AuthResult.failure(e.message);
    } catch (e) {
      return AuthResult.failure('Google 登入失敗：${e.toString()}');
    }
  }
}