import 'package:shared_preferences/shared_preferences.dart';
import 'package:tryzeon/core/config/app_constants.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/utils/app_logger.dart';
import 'package:tryzeon/feature/personal/settings/domain/entities/tryon_prompt_config.dart';
import 'package:tryzeon/feature/personal/settings/domain/repositories/settings_repository.dart';
import 'package:typed_result/typed_result.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  @override
  Future<Result<TryonPromptConfig, Failure>> getTryonPromptConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return Ok(
        TryonPromptConfig(
          scenePrompt: prefs.getString(AppConstants.keyTryonScenePrompt),
          transitionPrompt: prefs.getString(AppConstants.keyTryonTransitionPrompt),
        ),
      );
    } catch (e, stackTrace) {
      AppLogger.error('Failed to read tryon prompt config', e, stackTrace);
      return Err(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void, Failure>> setTryonPromptConfig(
    final TryonPromptConfig config,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await _write(prefs, AppConstants.keyTryonScenePrompt, config.scenePrompt);
      await _write(
        prefs,
        AppConstants.keyTryonTransitionPrompt,
        config.transitionPrompt,
      );
      return const Ok(null);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to save tryon prompt config', e, stackTrace);
      return Err(mapExceptionToFailure(e));
    }
  }

  Future<void> _write(
    final SharedPreferences prefs,
    final String key,
    final String? value,
  ) async {
    if (value != null && value.isNotEmpty) {
      await prefs.setString(key, value);
    } else {
      await prefs.remove(key);
    }
  }
}
