import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tryzeon/core/utils/app_logger.dart';
import 'package:tryzeon/feature/personal/settings/data/repositories/settings_repository_impl.dart';
import 'package:tryzeon/feature/personal/settings/domain/entities/tryon_preferences.dart';
import 'package:tryzeon/feature/personal/settings/domain/repositories/settings_repository.dart';
import 'package:tryzeon/feature/personal/settings/domain/usecases/get_tryon_preferences.dart';
import 'package:tryzeon/feature/personal/settings/domain/usecases/set_tryon_preferences.dart';
import 'package:typed_result/typed_result.dart';

part 'settings_providers.g.dart';

@riverpod
SettingsRepository settingsRepository(final Ref ref) {
  return SettingsRepositoryImpl();
}

@riverpod
GetTryonPreferences getTryonPreferencesUseCase(final Ref ref) =>
    GetTryonPreferences(ref.watch(settingsRepositoryProvider));

@riverpod
SetTryonPreferences setTryonPreferencesUseCase(final Ref ref) =>
    SetTryonPreferences(ref.watch(settingsRepositoryProvider));

@riverpod
class TryonPreferencesNotifier extends _$TryonPreferencesNotifier {
  @override
  Future<TryonPreferences> build() async {
    final result = await ref.read(getTryonPreferencesUseCaseProvider)();
    return result.isSuccess ? result.get()! : const TryonPreferences();
  }

  /// Every control writes through this as it changes, so there is nothing to
  /// confirm and closing the sheet cannot drop an edit.
  Future<void> apply(final TryonPreferences preferences) async {
    state = AsyncData(preferences);
    final result = await ref.read(setTryonPreferencesUseCaseProvider)(preferences);
    if (result.isFailure) {
      AppLogger.error('Failed to persist tryon preferences', result.getError());
    }
  }
}
