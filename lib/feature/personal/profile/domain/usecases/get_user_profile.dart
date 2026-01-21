import 'package:tryzeon/feature/personal/profile/domain/entities/user_profile.dart';
import 'package:tryzeon/feature/personal/profile/domain/repositories/user_profile_repository.dart';
import 'package:typed_result/typed_result.dart';

class GetUserProfile {
  GetUserProfile(this._repository);

  final UserProfileRepository _repository;

  Future<Result<UserProfile, String>> call({final bool forceRefresh = false}) {
    return _repository.getUserProfile(forceRefresh: forceRefresh);
  }
}
