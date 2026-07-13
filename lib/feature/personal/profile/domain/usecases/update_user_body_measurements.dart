import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/common/measurements/domain/entities/measurements.dart';
import 'package:tryzeon/feature/personal/profile/domain/repositories/user_profile_repository.dart';
import 'package:typed_result/typed_result.dart';

class UpdateUserBodyMeasurements {
  UpdateUserBodyMeasurements(this._repository);

  final UserProfileRepository _repository;

  Future<Result<void, Failure>> call({required final Measurements measurements}) {
    return _repository.updateUserBodyMeasurements(measurements: measurements);
  }
}
