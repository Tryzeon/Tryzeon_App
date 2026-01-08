import 'package:tryzeon/feature/personal/home/domain/entities/tryon_result.dart';
import 'package:tryzeon/feature/personal/home/domain/repositories/tryon_repository.dart';
import 'package:tryzeon/feature/personal/profile/domain/repositories/user_profile_repository.dart';
import 'package:typed_result/typed_result.dart';

class TryonUseCase {
  TryonUseCase({
    required final UserProfileRepository userProfileRepository,
    required final TryOnRepository tryOnRepository,
  }) : _userProfileRepository = userProfileRepository,
       _tryOnRepository = tryOnRepository;

  final UserProfileRepository _userProfileRepository;
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
      final profileResult = await _userProfileRepository.getUserProfile();

      // Check for error using pattern matching
      switch (profileResult) {
        case Err(:final error):
          return Err(error);
        case Ok(:final value):
          if (value.avatarPath == null || value.avatarPath!.isEmpty) {
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
