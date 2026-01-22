import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRemoteDataSource {
  AuthRemoteDataSource(this._supabase);
  final SupabaseClient _supabase;

  Future<void> signInWithOAuth(final OAuthProvider provider) async {
    final success = await _supabase.auth.signInWithOAuth(
      provider,
      redirectTo: 'io.supabase.tryzeon://login-callback',
      authScreenLaunchMode: LaunchMode.externalApplication,
    );

    if (!success) {
      throw Exception('OAuth sign-in failed');
    }

    // Wait for auth state change
    final user = await _supabase.auth.onAuthStateChange
        .firstWhere((final state) => state.event == AuthChangeEvent.signedIn)
        .then((final state) => state.session?.user);

    if (user == null) {
      throw Exception('Failed to get user information');
    }
  }

  Future<void> sendEmailOtp(final String email) async {
    await _supabase.auth.signInWithOtp(email: email);
  }

  Future<void> verifyEmailOtp({
    required final String email,
    required final String token,
  }) async {
    final response = await _supabase.auth.verifyOTP(
      type: OtpType.email,
      email: email,
      token: token,
    );

    if (response.session == null) {
      throw Exception('驗證碼無效或已過期');
    }
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  User? getCurrentUser() {
    return _supabase.auth.currentSession?.user;
  }
}
