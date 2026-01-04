import 'dart:io';

import 'package:tryzeon/feature/personal/home/domain/entities/avatar.dart';

class AvatarModel extends Avatar {
  const AvatarModel({required super.avatarPath, required super.avatarFile});

  factory AvatarModel.fromRecord({
    required final String avatarPath,
    required final File avatarFile,
  }) {
    return AvatarModel(avatarPath: avatarPath, avatarFile: avatarFile);
  }
}
