import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tryzeon/feature/personal/settings/data/repositories/settings_repository_impl.dart';
import 'package:tryzeon/feature/personal/settings/domain/entities/video_prompt_config.dart';
import 'package:tryzeon/feature/personal/settings/domain/repositories/settings_repository.dart';
import 'package:tryzeon/feature/personal/settings/domain/usecases/get_video_prompt_config.dart';
import 'package:tryzeon/feature/personal/settings/domain/usecases/set_video_prompt_config.dart';
import 'package:typed_result/typed_result.dart';

part 'settings_providers.g.dart';

@riverpod
SettingsRepository settingsRepository(final Ref ref) {
  return SettingsRepositoryImpl();
}

@riverpod
GetVideoPromptConfig getVideoPromptConfigUseCase(final Ref ref) =>
    GetVideoPromptConfig(ref.watch(settingsRepositoryProvider));

@riverpod
SetVideoPromptConfig setVideoPromptConfigUseCase(final Ref ref) =>
    SetVideoPromptConfig(ref.watch(settingsRepositoryProvider));

@riverpod
class VideoPromptConfigNotifier extends _$VideoPromptConfigNotifier {
  @override
  Future<VideoPromptConfig> build() async {
    final result = await ref.read(getVideoPromptConfigUseCaseProvider)();
    return result.isSuccess ? result.get()! : const VideoPromptConfig();
  }

  Future<bool> save(final VideoPromptConfig config) async {
    final result = await ref.read(setVideoPromptConfigUseCaseProvider)(config);
    if (result.isSuccess) {
      state = AsyncData(config);
      return true;
    }
    return false;
  }
}
