import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/modules/revenue_cat/domain/entities/app_subscription_entitlement.dart';
import 'package:tryzeon/core/modules/revenue_cat/domain/repositories/revenue_cat_repository.dart';
import 'package:tryzeon/core/modules/revenue_cat/providers/revenue_cat_providers.dart';
import 'package:tryzeon/feature/personal/subscription/domain/entities/subscription_capabilities.dart';
import 'package:tryzeon/feature/personal/subscription/domain/repositories/subscription_capabilities_repository.dart';
import 'package:tryzeon/feature/personal/subscription/providers/subscription_capabilities_provider.dart';
import 'package:typed_result/typed_result.dart';

/// Feeds entitlements on demand, standing in for RevenueCat's customer-info
/// listener.
class _FakeRevenueCatRepository implements RevenueCatRepository {
  final _controller = StreamController<AppSubscriptionEntitlement>();

  void push(final AppSubscriptionTier tier) {
    _controller.add(
      AppSubscriptionEntitlement(
        tier: tier,
        expirationDate: null,
        productIdentifier: null,
      ),
    );
  }

  void pushError(final Failure failure) => _controller.addError(failure);

  @override
  Stream<AppSubscriptionEntitlement> watchAppSubscriptionEntitlement() =>
      _controller.stream;

  @override
  Future<Result<void, Failure>> logIn(final String userId) async => const Ok(null);

  @override
  Future<Result<void, Failure>> logOut() async => const Ok(null);
}

/// The tier → limits table, without Supabase or Isar.
class _FakeCapabilitiesRepository implements SubscriptionCapabilitiesRepository {
  final tiersAskedFor = <AppSubscriptionTier>[];

  @override
  Future<Result<SubscriptionCapabilities, Failure>> getCapabilitiesForTier(
    final AppSubscriptionTier tier,
  ) async {
    tiersAskedFor.add(tier);
    final videoLimit = tier == AppSubscriptionTier.max ? 3 : 0;
    return Ok(
      SubscriptionCapabilities(
        hasVideoAccess: videoLimit > 0,
        wardrobeLimit: 10,
        dailyTryonLimit: 5,
        dailyChatLimit: 5,
        dailyVideoLimit: videoLimit,
      ),
    );
  }
}

void main() {
  late _FakeRevenueCatRepository revenueCat;
  late _FakeCapabilitiesRepository capabilities;
  late ProviderContainer container;

  setUp(() {
    revenueCat = _FakeRevenueCatRepository();
    capabilities = _FakeCapabilitiesRepository();
    container = ProviderContainer(
      // Mirrors `customRetry`: only NetworkFailure backs off, everything else
      // fails fast. The failures below are not network ones.
      retry: (final _, final _) => null,
      overrides: [
        revenueCatRepositoryProvider.overrideWith((final ref) => revenueCat),
        subscriptionCapabilitiesRepositoryProvider.overrideWith(
          (final ref) => capabilities,
        ),
      ],
    );
    addTearDown(container.dispose);
  });

  /// Completes with the first emitted value satisfying [predicate].
  Future<SubscriptionCapabilities> firstWhere(
    final bool Function(SubscriptionCapabilities) predicate,
  ) {
    final completer = Completer<SubscriptionCapabilities>();
    final subscription = container.listen(subscriptionCapabilitiesProvider, (
      final _,
      final next,
    ) {
      final value = next.value;
      if (value != null && predicate(value) && !completer.isCompleted) {
        completer.complete(value);
      }
    }, fireImmediately: true);
    addTearDown(subscription.close);
    return completer.future.timeout(const Duration(seconds: 5));
  }

  test('capabilities follow a tier that arrives after the first one', () async {
    // The customer identity is linked asynchronously at startup, so the first
    // entitlement the app sees can be the anonymous customer's free tier.
    final locked = firstWhere((final c) => !c.hasVideoAccess);
    revenueCat.push(AppSubscriptionTier.free);
    await locked;

    // RevenueCat then reports the real customer. Nothing invalidates anything by
    // hand — video access has to unlock on its own.
    final unlocked = firstWhere((final c) => c.hasVideoAccess);
    revenueCat.push(AppSubscriptionTier.max);
    await unlocked;

    expect(capabilities.tiersAskedFor, [
      AppSubscriptionTier.free,
      AppSubscriptionTier.max,
    ]);
  });

  test('a RevenueCat failure surfaces as an error, not as the free tier', () async {
    // The old pull-based use case folded any RevenueCat failure into the free
    // tier, which locked video for paying customers whenever the SDK hiccuped.
    final subscription = container.listen(
      subscriptionCapabilitiesProvider,
      (final _, final _) {},
      fireImmediately: true,
    );
    addTearDown(subscription.close);

    revenueCat.pushError(const UnknownFailure('RevenueCat unreachable'));

    await expectLater(
      container.read(subscriptionCapabilitiesProvider.future),
      throwsA(isA<UnknownFailure>()),
    );
    expect(capabilities.tiersAskedFor, isEmpty);
  });
}
