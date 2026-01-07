import 'package:tryzeon/feature/personal/profile/domain/entities/user_profile.dart';
import 'package:typed_result/typed_result.dart';

abstract class UserProfileRepository {
  Future<UserProfile> getUserProfile();

  Future<Result<void, String>> updateUserProfile({
    required final UserProfile original,
    required final UserProfile target,
  });
}
