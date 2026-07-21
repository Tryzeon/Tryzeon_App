import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/auth/domain/entities/user_type.dart';
import 'package:tryzeon/feature/auth/providers/auth_providers.dart';
import 'package:typed_result/typed_result.dart';

part 'settings_controller.g.dart';

/// Account-level actions shared by the personal and store settings screens.
///
/// [state] tracks whichever action is in flight so a page can drive a
/// `LoadingOverlay` and surface the failure once; the [Result] is also returned
/// so a caller that needs to branch on the outcome can.
@riverpod
class SettingsController extends _$SettingsController {
  bool _mounted = true;

  @override
  FutureOr<void> build() async {
    ref.onDispose(() => _mounted = false);
  }

  Future<Result<void, Failure>> signOut() =>
      _run(() => ref.read(signOutUseCaseProvider)());

  /// Records which shell the app should open into next. Navigating there is the
  /// caller's job.
  Future<Result<void, Failure>> switchTo(final UserType type) =>
      _run(() => ref.read(setLastLoginTypeUseCaseProvider)(type));

  Future<Result<void, Failure>> deleteAccount() =>
      _run(() => ref.read(deleteAccountUseCaseProvider)());

  /// Runs [action] while reflecting it in [state]. The `_mounted` guard keeps a
  /// state write from landing on a disposed notifier when the page is popped
  /// mid-flight — the result still reaches the caller either way.
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
