import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/personal/settings/domain/entities/video_prompt_config.dart';
import 'package:tryzeon/feature/personal/settings/domain/repositories/settings_repository.dart';
import 'package:typed_result/typed_result.dart';

class SetVideoPromptConfig {
  SetVideoPromptConfig(this._repository);

  final SettingsRepository _repository;

  Future<Result<void, Failure>> call(final VideoPromptConfig config) =>
      _repository.setVideoPromptConfig(config);
}
