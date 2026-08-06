import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tryzeon/feature/personal/settings/data/repositories/settings_repository_impl.dart';
import 'package:tryzeon/feature/personal/settings/domain/entities/tryon_prompt_config.dart';
import 'package:tryzeon/feature/personal/settings/domain/repositories/settings_repository.dart';
import 'package:tryzeon/feature/personal/settings/domain/usecases/get_tryon_prompt_config.dart';
import 'package:tryzeon/feature/personal/settings/domain/usecases/set_tryon_prompt_config.dart';
import 'package:typed_result/typed_result.dart';

part 'settings_providers.g.dart';

@riverpod
SettingsRepository settingsRepository(final Ref ref) {
  return SettingsRepositoryImpl();
}

@riverpod
GetTryonPromptConfig getTryonPromptConfigUseCase(final Ref ref) =>
    GetTryonPromptConfig(ref.watch(settingsRepositoryProvider));

@riverpod
SetTryonPromptConfig setTryonPromptConfigUseCase(final Ref ref) =>
    SetTryonPromptConfig(ref.watch(settingsRepositoryProvider));

@riverpod
class TryonPromptConfigNotifier extends _$TryonPromptConfigNotifier {
  @override
  Future<TryonPromptConfig> build() async {
    final result = await ref.read(getTryonPromptConfigUseCaseProvider)();
    return result.isSuccess ? result.get()! : const TryonPromptConfig();
  }

  Future<bool> save(final TryonPromptConfig config) async {
    final result = await ref.read(setTryonPromptConfigUseCaseProvider)(config);
    if (result.isSuccess) {
      state = AsyncData(config);
      return true;
    }
    return false;
  }
}
