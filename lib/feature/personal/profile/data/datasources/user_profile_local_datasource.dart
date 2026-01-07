import 'package:tryzeon/feature/personal/profile/domain/entities/user_profile.dart';

class UserProfileLocalDataSource {
  UserProfile? _cachedProfile;

  UserProfile? getCachedProfile() => _cachedProfile;

  void updateCachedProfile(final UserProfile profile) {
    _cachedProfile = profile;
  }
}
