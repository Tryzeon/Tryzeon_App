import 'dart:io';

import 'package:tryzeon/core/utils/app_logger.dart';
import 'package:tryzeon/feature/personal/home/data/datasources/avatar_local_data_source.dart';
import 'package:tryzeon/feature/personal/home/data/datasources/avatar_remote_data_source.dart';
import 'package:tryzeon/feature/personal/home/data/models/avatar_model.dart';
import 'package:tryzeon/feature/personal/home/domain/entities/avatar.dart';
import 'package:tryzeon/feature/personal/home/domain/repositories/avatar_repository.dart';
import 'package:typed_result/typed_result.dart';

class AvatarRepositoryImpl implements AvatarRepository {
  AvatarRepositoryImpl({
    required final AvatarRemoteDataSource avatarRemoteDataSource,
    required final AvatarLocalDataSource avatarLocalDataSource,
  }) : _avatarRemoteDataSource = avatarRemoteDataSource,
       _avatarLocalDataSource = avatarLocalDataSource;

  final AvatarRemoteDataSource _avatarRemoteDataSource;
  final AvatarLocalDataSource _avatarLocalDataSource;

  @override
  Future<Result<Avatar?, String>> getAvatar({final bool forceRefresh = false}) async {
    try {
      // 1. Get avatarPath
      String? avatarPath;

      if (forceRefresh) {
        avatarPath = await _avatarRemoteDataSource.fetchAvatarPath();
      } else {
        avatarPath = _avatarLocalDataSource.getAvatarPath();
      }

      if (avatarPath == null) {
        return const Ok(null);
      }

      // 2. Check cached file
      if (!forceRefresh) {
        final cachedFile = await _avatarLocalDataSource.getAvatar(avatarPath);

        if (cachedFile != null) {
          return Ok(
            AvatarModel.fromRecord(avatarPath: avatarPath, avatarFile: cachedFile),
          );
        }
      }

      // 3. Download file from remote
      final avatarBytes = await _avatarRemoteDataSource.downloadAvatar(avatarPath);

      // 4. Save to local cache
      await _avatarLocalDataSource.saveAvatarBytes(
        avatarPath: avatarPath,
        avatarBytes: avatarBytes,
      );

      final avatarFile = await _avatarLocalDataSource.getAvatar(avatarPath);

      if (avatarFile == null) {
        return const Err('無法儲存頭像');
      }

      return Ok(AvatarModel.fromRecord(avatarPath: avatarPath, avatarFile: avatarFile));
    } catch (e) {
      AppLogger.error('頭像獲取失敗', e);
      return const Err('無法取得頭像，請稍後再試');
    }
  }

  @override
  Future<Result<Avatar, String>> uploadAvatar(final File image) async {
    try {
      // Get old avatarPath before upload to delete its cache later
      final oldAvatarPath = _avatarLocalDataSource.getAvatarPath();

      // Upload to remote (returns new path)
      final newAvatarPath = await _avatarRemoteDataSource.uploadAvatar(image);

      // Save new avatar to local cache
      await _avatarLocalDataSource.saveAvatar(
        avatarPath: newAvatarPath,
        avatarFile: image,
      );

      // Cleanup old avatar
      if (oldAvatarPath != null &&
          oldAvatarPath.isNotEmpty &&
          oldAvatarPath != newAvatarPath) {
        try {
          await _avatarRemoteDataSource.deleteAvatar(oldAvatarPath);
          await _avatarLocalDataSource.deleteAvatar(oldAvatarPath);
        } catch (e) {
          AppLogger.error('Failed to cleanup old avatar', e);
        }
      }

      final cachedFile = await _avatarLocalDataSource.getAvatar(newAvatarPath);

      return Ok(
        AvatarModel.fromRecord(
          avatarPath: newAvatarPath,
          avatarFile: cachedFile ?? image,
        ),
      );
    } catch (e) {
      AppLogger.error('頭像上傳失敗', e);
      return const Err('頭像上傳失敗，請稍後再試');
    }
  }
}
