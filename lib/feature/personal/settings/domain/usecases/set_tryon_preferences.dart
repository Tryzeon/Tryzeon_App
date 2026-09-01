import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/personal/settings/domain/entities/tryon_preferences.dart';
import 'package:tryzeon/feature/personal/settings/domain/repositories/settings_repository.dart';
import 'package:typed_result/typed_result.dart';

class SetTryonPreferences {
  SetTryonPreferences(this._repository);

  final SettingsRepository _repository;

  Future<Result<void, Failure>> call(final TryonPreferences preferences) =>
      _repository.setTryonPreferences(preferences);
}
