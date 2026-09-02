import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/core/modules/auth_identity/domain/services/auth_identity_service.dart';

class AuthIdentityServiceImpl implements AuthIdentityService {
  AuthIdentityServiceImpl(this._auth);

  final GoTrueClient _auth;

  // Supabase fires several events (`initialSession`, `tokenRefreshed`, ...) that
  // all resolve to the same identity, so only actual identity changes are
  // published.
  @override
  Stream<String?> watchUserId() => _watchUserId().distinct();

  Stream<String?> _watchUserId() async* {
    // `initialSession` is emitted asynchronously and may fire before this
    // subscribes, so the restored session is read directly instead.
    yield _auth.currentSession?.user.id;

    // The client's own session is authoritative; an event's payload is not
    // carried by every event type.
    yield* _auth.onAuthStateChange.map((final _) => _auth.currentSession?.user.id);
  }
}
