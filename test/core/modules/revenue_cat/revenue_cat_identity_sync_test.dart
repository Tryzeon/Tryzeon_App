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

/// Records identity calls and fails [logIn] as many times as asked, standing in
/// for a RevenueCat SDK that is unreachable at cold start.
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

  /// Lets the stream emission and the awaited identity call both settle.
  Future<void> settle() => Future<void>.delayed(Duration.zero);

  setUp(() {
    authUserIds = StreamController<String?>();
    addTearDown(authUserIds.close);
  });

  test('登入成功後，同一個 user id 的重複事件不會重打 logIn', () async {
    repository = _FakeRevenueCatRepository();
    build();

    authUserIds.add('user-a');
    await settle();
    authUserIds.add('user-a');
    await settle();

    expect(repository.loggedInUserIds, ['user-a']);
  });

  test('logIn 失敗不會鎖死：下一個 auth 事件會用同一個 user id 重試', () async {
    repository = _FakeRevenueCatRepository(logInFailures: 1);
    build();

    authUserIds.add('user-a');
    await settle();
    expect(repository.loggedInUserIds, ['user-a']);

    // 一次 token refresh 就足以復原，不必等使用者重新登入。
    authUserIds.add('user-a');
    await settle();

    expect(repository.loggedInUserIds, ['user-a', 'user-a']);
  });

  test('重試成功後就停止重試', () async {
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

  test('登出後再登入同一個帳號會重新 logIn', () async {
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

  test('未登入啟動時不會對匿名的 RevenueCat 打 logOut', () async {
    repository = _FakeRevenueCatRepository();
    build();

    authUserIds.add(null);
    await settle();

    expect(repository.logOutCount, 0);
  });

  test('切換帳號時不會漏掉後到的使用者', () async {
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
