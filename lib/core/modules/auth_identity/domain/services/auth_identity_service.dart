abstract class AuthIdentityService {
  /// Id of the signed-in user: first the session restored at startup, then one
  /// value per auth event.
  ///
  /// Duplicate values are deliberately not filtered out. A repeated id is a
  /// retry budget — when an identity-binding side effect fails, the next token
  /// refresh delivers the same id again and recovers it, without waiting for
  /// the user to sign in again.
  Stream<String?> watchUserId();
}
