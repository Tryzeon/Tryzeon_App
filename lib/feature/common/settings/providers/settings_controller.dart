import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/auth/domain/entities/user_type.dart';
import 'package:tryzeon/feature/auth/providers/auth_providers.dart';
import 'package:typed_result/typed_result.dart';

part 'settings_controller.g.dart';

@riverpod
class SettingsController extends _$SettingsController {
  bool _mounted = true;

  @override
  FutureOr<void> build() async {
    ref.onDispose(() => _mounted = false);
  }

  Future<Result<void, Failure>> signOut() =>
      _run(() => ref.read(signOutUseCaseProvider)());

  Future<Result<void, Failure>> switchTo(final UserType type) =>
      _run(() => ref.read(setLastLoginTypeUseCaseProvider)(type));

  Future<Result<void, Failure>> deleteAccount() =>
      _run(() => ref.read(deleteAccountUseCaseProvider)());

  /// The `_mounted` guard keeps a state write from landing on a disposed
  /// notifier when the page is popped mid-flight.
  Future<Result<void, Failure>> _run(
    final Future<Result<void, Failure>> Function() action,
  ) async {
    state = const AsyncLoading();
    final result = await action();

    if (!_mounted) return result;

    if (result.isFailure) {
      state = AsyncError(result.getError()!, StackTrace.current);
    } else {
      state = const AsyncData(null);
    }
    return result;
  }
}
