import 'package:tryzeon/feature/personal/home/domain/entities/tryon_result.dart';
import 'package:tryzeon/feature/personal/home/domain/repositories/avatar_repository.dart';
import 'package:tryzeon/feature/personal/home/domain/repositories/tryon_repository.dart';
import 'package:typed_result/typed_result.dart';

class TryonUseCase {
  TryonUseCase({
    required final AvatarRepository avatarRepository,
    required final TryOnRepository tryOnRepository,
  }) : _avatarRepository = avatarRepository,
       _tryOnRepository = tryOnRepository;

  final AvatarRepository _avatarRepository;
  final TryOnRepository _tryOnRepository;

  /// Performs virtual try-on.
  /// If [customAvatarBase64] is not provided, automatically fetches current user's avatarPath.
  /// This encapsulates the business logic: "use custom avatar if provided, otherwise use current user avatar"
  Future<Result<TryonResult, String>> call({
    final String? customAvatarBase64,
    final String? clothesBase64,
    final String? clothesPath,
  }) async {
    // Business Logic: If no custom avatar provided, fetch current user's avatar path
    String? avatarPathToUse;
    if (customAvatarBase64 == null) {
      final avatarResult = await _avatarRepository.getAvatar();

      // Check for error using pattern matching
      switch (avatarResult) {
        case Err(:final error):
          return Err(error);
        case Ok(:final value):
          if (value == null) {
            return const Err('請先上傳您的照片');
          }
          avatarPathToUse = value.avatarPath;
      }
    }

    return _tryOnRepository.tryon(
      avatarBase64: customAvatarBase64,
      avatarPath: avatarPathToUse,
      clothesBase64: clothesBase64,
      clothesPath: clothesPath,
    );
  }
}
