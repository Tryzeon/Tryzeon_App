import 'package:shared_preferences/shared_preferences.dart';
import 'package:tryzeon/core/config/app_constants.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/utils/app_logger.dart';
import 'package:tryzeon/feature/personal/settings/domain/entities/video_prompt_config.dart';
import 'package:tryzeon/feature/personal/settings/domain/repositories/settings_repository.dart';
import 'package:typed_result/typed_result.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  @override
  Future<Result<VideoPromptConfig, Failure>> getVideoPromptConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return Ok(
        VideoPromptConfig(
          scenePrompt: prefs.getString(AppConstants.keyVideoScenePrompt),
          transitionPrompt: prefs.getString(AppConstants.keyVideoTransitionPrompt),
        ),
      );
    } catch (e, stackTrace) {
      AppLogger.error('Failed to read video prompt config', e, stackTrace);
      return Err(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void, Failure>> setVideoPromptConfig(
    final VideoPromptConfig config,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (config.scenePrompt != null && config.scenePrompt!.isNotEmpty) {
        await prefs.setString(AppConstants.keyVideoScenePrompt, config.scenePrompt!);
      } else {
        await prefs.remove(AppConstants.keyVideoScenePrompt);
      }

      if (config.transitionPrompt != null && config.transitionPrompt!.isNotEmpty) {
        await prefs.setString(
          AppConstants.keyVideoTransitionPrompt,
          config.transitionPrompt!,
        );
      } else {
        await prefs.remove(AppConstants.keyVideoTransitionPrompt);
      }

      return const Ok(null);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to save video prompt config', e, stackTrace);
      return Err(mapExceptionToFailure(e));
    }
  }
}
