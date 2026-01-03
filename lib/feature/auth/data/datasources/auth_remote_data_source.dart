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

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  User? getCurrentUser() {
    return _supabase.auth.currentSession?.user;
  }
}
