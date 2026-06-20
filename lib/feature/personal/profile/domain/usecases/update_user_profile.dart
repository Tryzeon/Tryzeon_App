import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/age_range.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/gender.dart';
import 'package:tryzeon/feature/personal/profile/domain/repositories/user_profile_repository.dart';
import 'package:typed_result/typed_result.dart';

class UpdateUserProfile {
  UpdateUserProfile(this._repository);

  final UserProfileRepository _repository;

  Future<Result<void, Failure>> call({
    required final String name,
    final Gender? gender,
    final AgeRange? ageRange,
  }) {
    return _repository.updateUserProfile(
      name: name,
      gender: gender,
      ageRange: ageRange,
    );
  }
}
