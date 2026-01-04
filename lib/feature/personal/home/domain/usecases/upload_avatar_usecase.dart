import 'dart:io';

import 'package:tryzeon/feature/personal/home/domain/entities/avatar.dart';
import 'package:tryzeon/feature/personal/home/domain/repositories/avatar_repository.dart';
import 'package:typed_result/typed_result.dart';

class UploadAvatarUseCase {
  UploadAvatarUseCase(this._repository);
  final AvatarRepository _repository;

  Future<Result<Avatar, String>> call(final File image) {
    return _repository.uploadAvatar(image);
  }
}
