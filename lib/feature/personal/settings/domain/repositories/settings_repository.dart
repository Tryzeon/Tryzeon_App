import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/personal/settings/domain/entities/video_prompt_config.dart';
import 'package:typed_result/typed_result.dart';

abstract class SettingsRepository {
  Future<Result<VideoPromptConfig, Failure>> getVideoPromptConfig();
  Future<Result<void, Failure>> setVideoPromptConfig(final VideoPromptConfig config);
}
