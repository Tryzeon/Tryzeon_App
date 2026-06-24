import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tryzeon/feature/personal/home/domain/entities/video_prompt_config.dart';
import 'package:tryzeon/feature/personal/settings/data/repositories/settings_repository_impl.dart';
import 'package:tryzeon/feature/personal/settings/domain/repositories/settings_repository.dart';
import 'package:typed_result/typed_result.dart';

part 'settings_providers.g.dart';

@riverpod
SettingsRepository settingsRepository(final Ref ref) {
  return SettingsRepositoryImpl();
}

@riverpod
class VideoPromptConfigNotifier extends _$VideoPromptConfigNotifier {
  @override
  Future<VideoPromptConfig> build() async {
    final repository = ref.read(settingsRepositoryProvider);
    final result = await repository.getVideoPromptConfig();
    return result.isSuccess ? result.get()! : const VideoPromptConfig();
  }

  Future<bool> save(final VideoPromptConfig config) async {
    final repository = ref.read(settingsRepositoryProvider);
    final result = await repository.setVideoPromptConfig(config);
    if (result.isSuccess) {
      state = AsyncData(config);
      return true;
    }
    return false;
  }
}
