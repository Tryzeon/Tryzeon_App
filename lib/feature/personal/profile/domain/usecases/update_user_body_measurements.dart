import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/common/body_measurements/domain/entities/body_measurements.dart';
import 'package:tryzeon/feature/personal/profile/domain/repositories/user_profile_repository.dart';
import 'package:typed_result/typed_result.dart';

class UpdateUserBodyMeasurements {
  UpdateUserBodyMeasurements(this._repository);

  final UserProfileRepository _repository;

  Future<Result<void, Failure>> call({required final BodyMeasurements measurements}) {
    return _repository.updateUserBodyMeasurements(measurements: measurements);
  }
}
