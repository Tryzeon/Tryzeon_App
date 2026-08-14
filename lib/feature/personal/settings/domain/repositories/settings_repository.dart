import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/personal/settings/domain/entities/tryon_prompt_config.dart';
import 'package:typed_result/typed_result.dart';

abstract class SettingsRepository {
  Future<Result<TryonPromptConfig, Failure>> getTryonPromptConfig();
  Future<Result<void, Failure>> setTryonPromptConfig(final TryonPromptConfig config);
  Future<Result<void, Failure>> clearTryonPromptConfig();
}
