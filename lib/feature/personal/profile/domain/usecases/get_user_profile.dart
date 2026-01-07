import 'package:tryzeon/feature/personal/profile/domain/entities/user_profile.dart';
import 'package:tryzeon/feature/personal/profile/domain/repositories/user_profile_repository.dart';

class GetUserProfile {
  GetUserProfile(this._repository);

  final UserProfileRepository _repository;

  Future<UserProfile> call() {
    return _repository.getUserProfile();
  }
}
