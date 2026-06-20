import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/common/clothing_style/entities/clothing_style.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/age_range.dart';
import 'package:tryzeon/feature/personal/profile/domain/entities/gender.dart';
import 'package:tryzeon/feature/personal/profile/domain/repositories/user_profile_repository.dart';
import 'package:typed_result/typed_result.dart';

class CompleteOnboarding {
  CompleteOnboarding(this._repository);

  final UserProfileRepository _repository;

  Future<Result<void, Failure>> call({
    final Gender? gender,
    final AgeRange? ageRange,
    final List<ClothingStyle>? stylePreferences,
  }) async {
    return _repository.completeUserOnboarding(
      gender: gender,
      ageRange: ageRange,
      stylePreferences: stylePreferences,
    );
  }
}
