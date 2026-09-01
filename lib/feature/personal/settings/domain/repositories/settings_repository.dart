import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/personal/settings/domain/entities/tryon_preferences.dart';
import 'package:typed_result/typed_result.dart';

abstract class SettingsRepository {
  Future<Result<TryonPreferences, Failure>> getTryonPreferences();
  Future<Result<void, Failure>> setTryonPreferences(final TryonPreferences config);
  Future<Result<void, Failure>> clearTryonPreferences();
}
