import 'package:package_info_plus/package_info_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/auth/domain/entities/user_type.dart';
import 'package:tryzeon/feature/auth/providers/auth_providers.dart';
import 'package:typed_result/typed_result.dart';

part 'personal_settings_controller.g.dart';

@riverpod
class PersonalSettingsController extends _$PersonalSettingsController {
  bool _mounted = true;

  @override
  FutureOr<void> build() async {
    ref.onDispose(() => _mounted = false);
    // Initial build doesn't need to do anything specifically
    // But we might want to load version info here if we want to expose it via state
  }

  Future<String> getAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return '${packageInfo.version} (${packageInfo.buildNumber})';
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    final signOutUseCase = ref.read(signOutUseCaseProvider);
    final result = await signOutUseCase();

    if (!_mounted) return;

    if (result.isFailure) {
      state = AsyncError(result.getError()!, StackTrace.current);
    } else {
      state = const AsyncData(null);
    }
  }

  Future<void> switchToStore() async {
    state = const AsyncLoading();
    final setLoginTypeUseCase = ref.read(setLastLoginTypeUseCaseProvider);
    final result = await setLoginTypeUseCase(UserType.store);

    if (!_mounted) return;

    if (result.isFailure) {
      state = AsyncError(result.getError()!, StackTrace.current);
    } else {
      state = const AsyncData(null);
    }
  }

  Future<Result<void, Failure>> deleteAccount() async {
    state = const AsyncLoading();
    final deleteAccountUseCase = ref.read(deleteAccountUseCaseProvider);
    final result = await deleteAccountUseCase();

    if (!_mounted) return result;

    if (result.isFailure) {
      state = AsyncError(result.getError()!, StackTrace.current);
      return result;
    } else {
      state = const AsyncData(null);
      return const Ok(null);
    }
  }
}
