import 'dart:io';

import 'package:tryzeon/feature/personal/profile/domain/entities/user_profile.dart';
import 'package:tryzeon/feature/personal/profile/domain/repositories/user_profile_repository.dart';
import 'package:typed_result/typed_result.dart';

class UpdateUserProfile {
  UpdateUserProfile(this._repository);

  final UserProfileRepository _repository;

  Future<Result<void, String>> call({
    required final UserProfile original,
    required final UserProfile target,
    final File? avatarFile,
  }) {
    return _repository.updateUserProfile(
      original: original,
      target: target,
      avatarFile: avatarFile,
    );
  }
}
