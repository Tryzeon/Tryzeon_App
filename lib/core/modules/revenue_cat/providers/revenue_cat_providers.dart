import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/core/modules/revenue_cat/data/repositories/revenue_cat_repository_impl.dart';
import 'package:tryzeon/core/modules/revenue_cat/domain/entities/app_subscription_entitlement.dart';
import 'package:tryzeon/core/modules/revenue_cat/domain/repositories/revenue_cat_repository.dart';
import 'package:tryzeon/core/modules/revenue_cat/domain/usecases/log_in_revenue_cat.dart';
import 'package:tryzeon/core/modules/revenue_cat/domain/usecases/log_out_revenue_cat.dart';
import 'package:tryzeon/core/modules/revenue_cat/domain/usecases/watch_app_subscription_entitlement.dart';
import 'package:tryzeon/core/utils/app_logger.dart';
import 'package:typed_result/typed_result.dart';

part 'revenue_cat_providers.g.dart';

// ── Repository ──────────────────────────────────────────────────────────────

@Riverpod(keepAlive: true)
RevenueCatRepository revenueCatRepository(final Ref ref) {
  return RevenueCatRepositoryImpl();
}

// ── Use Case Providers ───────────────────────────────────────────────────────

@riverpod
WatchAppSubscriptionEntitlement watchAppSubscriptionEntitlementUseCase(final Ref ref) {
  return WatchAppSubscriptionEntitlement(ref.watch(revenueCatRepositoryProvider));
}

@riverpod
LogInRevenueCat logInRevenueCatUseCase(final Ref ref) {
  return LogInRevenueCat(ref.watch(revenueCatRepositoryProvider));
}

@riverpod
LogOutRevenueCat logOutRevenueCatUseCase(final Ref ref) {
  return LogOutRevenueCat(ref.watch(revenueCatRepositoryProvider));
}

/// App-wide source of truth for the customer's plan.
///
/// Kept alive so a single RevenueCat listener backs the whole app: every screen
/// reads the same entitlement, and a change (identity link at startup, purchase,
/// renewal, cross-device upgrade) re-emits to all of them at once instead of
/// leaving each screen holding whatever was true when it first mounted.
@Riverpod(keepAlive: true)
Stream<AppSubscriptionEntitlement> appSubscriptionEntitlement(final Ref ref) {
  return ref.watch(watchAppSubscriptionEntitlementUseCaseProvider)();
}

// ── Identity Sync ─────────────────────────────────────────────────────────────

/// Single source of truth for keeping the RevenueCat App User ID in sync with
/// the Supabase auth identity.
///
/// RevenueCat is configured anonymously at startup (see `main.dart`); this
/// listener links the anonymous customer to the Supabase auth UUID on sign-in
/// and reverts to a fresh anonymous ID on sign-out. Centralizing it here means
/// every current and future auth path is covered without each one having to
/// remember to call `logIn`/`logOut`.
///
/// Must be kept alive for the whole app lifecycle — read it once at the root
/// widget so the subscription is established at startup.
@Riverpod(keepAlive: true)
void revenueCatIdentitySync(final Ref ref) {
  final logIn = ref.watch(logInRevenueCatUseCaseProvider);
  final logOut = ref.watch(logOutRevenueCatUseCaseProvider);
  final auth = Supabase.instance.client.auth;

  String? syncedUserId;

  Future<void> syncLogIn(final String userId) async {
    if (syncedUserId == userId) return;
    syncedUserId = userId;
    final result = await logIn(userId);
    if (result.isFailure) {
      AppLogger.error(
        'RevenueCat login failed (ignored)',
        result.getError()!,
        StackTrace.current,
      );
    }
  }

  Future<void> syncLogOut() async {
    syncedUserId = null;
    final result = await logOut();
    if (result.isFailure) {
      AppLogger.error(
        'RevenueCat logout failed (ignored)',
        result.getError()!,
        StackTrace.current,
      );
    }
  }

  // Link an already-restored session at startup. The `initialSession` event is
  // emitted asynchronously and may fire before this listener subscribes, so we
  // read the current session directly rather than relying on the stream.
  final initialUser = auth.currentSession?.user;
  if (initialUser != null) {
    unawaited(syncLogIn(initialUser.id));
  }

  final subscription = auth.onAuthStateChange.listen((final state) {
    switch (state.event) {
      case AuthChangeEvent.signedIn:
      case AuthChangeEvent.initialSession:
      case AuthChangeEvent.tokenRefreshed:
        final user = state.session?.user;
        if (user != null) {
          unawaited(syncLogIn(user.id));
        }
      case AuthChangeEvent.signedOut:
        unawaited(syncLogOut());
      default:
        break;
    }
  });

  ref.onDispose(subscription.cancel);
}
