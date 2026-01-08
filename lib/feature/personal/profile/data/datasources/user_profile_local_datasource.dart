import 'package:tryzeon/feature/personal/profile/domain/entities/user_profile.dart';

class UserProfileLocalDataSource {
  UserProfile? _cachedProfile;

  UserProfile? get cachedProfile => _cachedProfile;

  set cachedProfile(final UserProfile profile) {
    _cachedProfile = profile;
  }
}
