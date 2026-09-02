import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tryzeon/core/di/core_providers.dart';
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
///
/// Only a *confirmed* link updates [syncedUserId]. Recording the intent instead
/// would strand a customer on the anonymous RevenueCat id — and therefore on the
/// free tier — for the rest of the session whenever the first attempt happens to
/// fail, with every later auth event skipped as already handled.
@Riverpod(keepAlive: true)
void revenueCatIdentitySync(final Ref ref) {
  final logIn = ref.watch(logInRevenueCatUseCaseProvider);
  final logOut = ref.watch(logOutRevenueCatUseCaseProvider);

  String? syncedUserId;

  Future<void> syncLogIn(final String userId) async {
    if (syncedUserId == userId) return;

    final result = await logIn(userId);
    if (result.isFailure) {
      AppLogger.error(
        'RevenueCat login failed; retrying on the next auth event',
        result.getError()!,
        StackTrace.current,
      );
      return;
    }
    syncedUserId = userId;
  }

  Future<void> syncLogOut() async {
    if (syncedUserId == null) return;

    final result = await logOut();
    if (result.isFailure) {
      AppLogger.error(
        'RevenueCat logout failed; the customer stays linked',
        result.getError()!,
        StackTrace.current,
      );
      return;
    }
    syncedUserId = null;
  }

  // Serialized so an id arriving mid-call is neither dropped nor raced against
  // the call already in flight.
  var pending = Future<void>.value();

  final subscription = ref
      .watch(authIdentityServiceProvider)
      .watchUserId()
      .listen((final userId) {
        pending = pending.then(
          (final _) => userId == null ? syncLogOut() : syncLogIn(userId),
        );
      });

  ref.onDispose(subscription.cancel);
}
