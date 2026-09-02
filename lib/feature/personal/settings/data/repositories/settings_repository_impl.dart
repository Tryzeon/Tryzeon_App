import 'package:shared_preferences/shared_preferences.dart';
import 'package:tryzeon/core/config/app_constants.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/utils/app_logger.dart';
import 'package:tryzeon/feature/personal/settings/domain/entities/tryon_preferences.dart';
import 'package:tryzeon/feature/personal/settings/domain/repositories/settings_repository.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_engine.dart';
import 'package:typed_result/typed_result.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  @override
  Future<Result<TryonPreferences, Failure>> getTryonPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return Ok(
        TryonPreferences(
          scenePrompt: prefs.getString(AppConstants.keyTryonScenePrompt),
          stylingPrompt: prefs.getString(AppConstants.keyTryonStylingPrompt),
          transitionPrompt: prefs.getString(AppConstants.keyTryonTransitionPrompt),
          engine: TryonEngine.values.firstWhere(
            (final engine) =>
                engine.name == prefs.getString(AppConstants.keyTryonEngine),
            orElse: () => TryonEngine.standard,
          ),
        ),
      );
    } catch (e, stackTrace) {
      AppLogger.error('Failed to read tryon preferences', e, stackTrace);
      return Err(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void, Failure>> setTryonPreferences(
    final TryonPreferences preferences,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await _write(prefs, AppConstants.keyTryonScenePrompt, preferences.scenePrompt);
      await _write(
        prefs,
        AppConstants.keyTryonStylingPrompt,
        preferences.stylingPrompt,
      );
      await _write(
        prefs,
        AppConstants.keyTryonTransitionPrompt,
        preferences.transitionPrompt,
      );
      await prefs.setString(
        AppConstants.keyTryonEngine,
        preferences.engine.name,
      );
      return const Ok(null);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to save tryon preferences', e, stackTrace);
      return Err(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Result<void, Failure>> clearTryonPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.keyTryonScenePrompt);
      await prefs.remove(AppConstants.keyTryonStylingPrompt);
      await prefs.remove(AppConstants.keyTryonTransitionPrompt);
      await prefs.remove(AppConstants.keyTryonEngine);
      return const Ok(null);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to clear tryon preferences', e, stackTrace);
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
