import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/di/core_providers.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/modules/auth_identity/domain/services/auth_identity_service.dart';
import 'package:tryzeon/core/modules/revenue_cat/domain/entities/app_subscription_entitlement.dart';
import 'package:tryzeon/core/modules/revenue_cat/domain/repositories/revenue_cat_repository.dart';
import 'package:tryzeon/core/modules/revenue_cat/providers/revenue_cat_providers.dart';
import 'package:typed_result/typed_result.dart';

class _FakeRevenueCatRepository implements RevenueCatRepository {
  _FakeRevenueCatRepository({this.logInFailures = 0});

  int logInFailures;
  final loggedInUserIds = <String>[];
  var logOutCount = 0;

  @override
  Future<Result<void, Failure>> logIn(final String userId) async {
    loggedInUserIds.add(userId);
    if (logInFailures > 0) {
      logInFailures--;
      return const Err(UnknownFailure('offline'));
    }
    return const Ok(null);
  }

  @override
  Future<Result<void, Failure>> logOut() async {
    logOutCount++;
    return const Ok(null);
  }

  @override
  Stream<AppSubscriptionEntitlement> watchAppSubscriptionEntitlement() =>
      const Stream.empty();
}

class _FakeAuthIdentityService implements AuthIdentityService {
  _FakeAuthIdentityService(this._userIds);

  final Stream<String?> _userIds;

  @override
  Stream<String?> watchUserId() => _userIds;
}

void main() {
  late StreamController<String?> authUserIds;
  late _FakeRevenueCatRepository repository;

  void build() {
    final container = ProviderContainer(
      overrides: [
        revenueCatRepositoryProvider.overrideWithValue(repository),
        authIdentityServiceProvider.overrideWithValue(
          _FakeAuthIdentityService(authUserIds.stream),
        ),
      ],
    );
    addTearDown(container.dispose);

    // Mirrors the root widget's `ref.watch`: the sync only runs while something
    // holds it, so a bare `read` would dispose it before any auth event lands.
    container.listen(
      revenueCatIdentitySyncProvider,
      (final _, final _) {},
      fireImmediately: true,
    );
  }

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  setUp(() {
    authUserIds = StreamController<String?>();
    addTearDown(authUserIds.close);
  });

  test('repeated events for the same user id do not call logIn again', () async {
    repository = _FakeRevenueCatRepository();
    build();

    authUserIds.add('user-a');
    await settle();
    authUserIds.add('user-a');
    await settle();

    expect(repository.loggedInUserIds, ['user-a']);
  });

  test('a failed logIn retries on the next auth event with the same user id', () async {
    repository = _FakeRevenueCatRepository(logInFailures: 1);
    build();

    authUserIds.add('user-a');
    await settle();
    expect(repository.loggedInUserIds, ['user-a']);

    // A single token refresh is enough to recover, without waiting for the user
    // to sign in again.
    authUserIds.add('user-a');
    await settle();

    expect(repository.loggedInUserIds, ['user-a', 'user-a']);
  });

  test('retrying stops once it succeeds', () async {
    repository = _FakeRevenueCatRepository(logInFailures: 1);
    build();

    authUserIds.add('user-a');
    await settle();
    authUserIds.add('user-a');
    await settle();
    authUserIds.add('user-a');
    await settle();

    expect(repository.loggedInUserIds, ['user-a', 'user-a']);
  });

  test('signing out and back in to the same account calls logIn again', () async {
    repository = _FakeRevenueCatRepository();
    build();

    authUserIds.add('user-a');
    await settle();
    authUserIds.add(null);
    await settle();
    authUserIds.add('user-a');
    await settle();

    expect(repository.logOutCount, 1);
    expect(repository.loggedInUserIds, ['user-a', 'user-a']);
  });

  test('starting up signed out does not logOut an anonymous RevenueCat', () async {
    repository = _FakeRevenueCatRepository();
    build();

    authUserIds.add(null);
    await settle();

    expect(repository.logOutCount, 0);
  });

  test('switching accounts does not drop the user that arrives later', () async {
    repository = _FakeRevenueCatRepository();
    build();

    authUserIds
      ..add('user-a')
      ..add('user-b');
    await settle();
    await settle();

    expect(repository.loggedInUserIds, ['user-a', 'user-b']);
  });
}
