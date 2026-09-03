import 'package:flutter/services.dart';
import 'package:flutter_line_sdk/flutter_line_sdk.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/core/config/app_constants.dart';
import 'package:tryzeon/core/error/exceptions.dart';
import 'package:tryzeon/core/utils/app_logger.dart';
import 'package:tryzeon/core/utils/crypto_utils.dart';

class AuthRemoteDataSource {
  AuthRemoteDataSource(this._supabase);
  final SupabaseClient _supabase;

  Future<void> signInWithOAuthProvider(final OAuthProvider provider) async {
    final success = await _supabase.auth.signInWithOAuth(
      provider,
      redirectTo: AppConstants.authCallbackUrl,
      authScreenLaunchMode: LaunchMode.externalApplication,
    );

    if (!success) {
      throw const ServerException();
    }

    final user = await _supabase.auth.onAuthStateChange
        .firstWhere((final state) => state.event == AuthChangeEvent.signedIn)
        .then((final state) => state.session?.user);

    if (user == null) {
      throw const UnauthenticatedException();
    }
  }

  Future<void> signInWithAppleNative() async {
    try {
      final rawNonce = CryptoUtils.generateNonce();
      final hashedNonce = CryptoUtils.sha256Hash(rawNonce);

      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
        nonce: hashedNonce,
      );

      final idToken = credential.identityToken;
      if (idToken == null) {
        throw const UnauthenticatedException();
      }

      await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: idToken,
        nonce: rawNonce,
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled ||
          e.code == AuthorizationErrorCode.unknown) {
        throw const UserCanceledException();
      }
      rethrow;
    }
  }

  Future<void> signInWithGoogleNative() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn.instance;
      await googleSignIn.initialize(serverClientId: AppConstants.googleServerClientId);

      final googleUser = await googleSignIn.authenticate();
      final googleAuth = googleUser.authentication;
      final idToken = googleAuth.idToken;

      await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken!,
        // accessToken is not required for Supabase authentication with Google
      );
    } on PlatformException catch (e, stackTrace) {
      AppLogger.error(
        'Google sign-in PlatformException '
        '[code=${e.code}] message=${e.message} details=${e.details}',
        e,
        stackTrace,
      );
      rethrow;
    } on GoogleSignInException catch (e, stackTrace) {
      AppLogger.error(
        'Google sign-in GoogleSignInException '
        '[code=${e.code.name}] description=${e.description} details=${e.details}',
        e,
        stackTrace,
      );
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw const UserCanceledException();
      }
      rethrow;
    }
  }

  /// LINE 沒有 Supabase provider，所以 id_token 換 session 這步交給
  /// `line-auth` edge function：它對 LINE 驗證 token、把 LINE userId 對到既有
  /// 的 auth user（LIFF 與官方帳號寫的是同一個），再回一個 refresh token。
  Future<void> signInWithLineNative() async {
    try {
      // `openid` 是必要的 scope，少了它 idTokenRaw 會是 null。
      final rawNonce = CryptoUtils.generateNonce();
      final result = await LineSDK.instance.login(
        scopes: ['profile', 'openid'],
        option: LoginOption(false, 'normal')..idTokenNonce = rawNonce,
      );

      final idToken = result.accessToken.idTokenRaw;
      if (idToken == null) {
        throw const UnauthenticatedException();
      }

      final response = await _supabase.functions.invoke(
        AppConstants.functionLineAuth,
        body: {'idToken': idToken, 'nonce': rawNonce},
      );

      final data = response.data;
      final refreshToken = data is Map ? data['refreshToken'] as String? : null;
      if (refreshToken == null) {
        throw const ServerException();
      }

      await _supabase.auth.setSession(refreshToken);
    } on PlatformException catch (e, stackTrace) {
      AppLogger.error(
        'LINE sign-in PlatformException '
        '[code=${e.code}] message=${e.message} details=${e.details}',
        e,
        stackTrace,
      );
      const cancelCodes = {'CANCEL', '3003', '0'};
      if (cancelCodes.contains(e.code.toUpperCase())) {
        throw const UserCanceledException();
      }
      rethrow;
    }
  }

  Future<void> sendEmailOTP(final String email) async {
    await _supabase.auth.signInWithOtp(email: email);
  }

  Future<void> verifyEmailOTP({
    required final String email,
    required final String token,
  }) async {
    final response = await _supabase.auth.verifyOTP(
      type: OtpType.email,
      email: email,
      token: token,
    );

    if (response.session == null) {
      throw const UnauthenticatedException();
    }
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  Future<void> signOutGoogle() async {
    await GoogleSignIn.instance.signOut();
  }

  /// Throws when there is no LINE session, which is the normal case for a user
  /// who signed in another way.
  Future<void> signOutLine() async {
    await LineSDK.instance.logout();
  }

  User? getCurrentUser() {
    return _supabase.auth.currentSession?.user;
  }

  Future<void> deleteAccount() async {
    await _supabase.functions.invoke(AppConstants.functionDeleteAccount);
  }
}
