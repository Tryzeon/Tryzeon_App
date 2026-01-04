import 'dart:io';

import 'package:tryzeon/feature/personal/home/domain/entities/avatar.dart';
import 'package:typed_result/typed_result.dart';

abstract class AvatarRepository {
  Future<Result<Avatar?, String>> getAvatar({final bool forceRefresh = false});

  Future<Result<Avatar, String>> uploadAvatar(final File image);
}
