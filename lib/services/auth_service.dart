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
      final metadata = {
        'user_type': userType.name,
        'name': name
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
      final actualUserType = userMetadata?['user_type'];
      
      if (actualUserType != expectedUserType.name) {
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

  /// 獲取當前用戶
  static User? get currentUser => _supabase.auth.currentUser;

  /// 獲取當前用戶類型
  static UserType? get currentUserType {
    final user = currentUser;
    if (user == null) return null;
    
    final userTypeString = user.userMetadata?['user_type'];
    if (userTypeString == null) return null;
    
    return UserType.values.firstWhere(
      (type) => type.name == userTypeString,
      orElse: () => UserType.personal,
    );
  }

  /// 檢查用戶是否已登入
  static bool get isAuthenticated => currentUser != null;

  /// 檢查是否為個人用戶
  static bool get isPersonalUser => currentUserType == UserType.personal;

  /// 檢查是否為店家用戶
  static bool get isStoreUser => currentUserType == UserType.store;

  /// 獲取當前用戶的顯示名稱
  static String? get displayName {
    final user = currentUser;
    if (user == null) return null;
    
    // 優先使用 user_metadata 中的 display_name
    final displayName = user.userMetadata?['name'] as String?;
    if (displayName != null && displayName.isNotEmpty) {
      return displayName;
    }
    
    return "無名氏";
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

      await _supabase.auth.updateUser(
        UserAttributes(
          data: {'user_type': userType.name},
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