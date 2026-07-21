import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/utils/app_logger.dart';
import 'package:tryzeon/feature/personal/profile/providers/personal_profile_providers.dart';
import 'package:tryzeon/feature/personal/settings/providers/settings_providers.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_garment.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_image_source.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_mode.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_request.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/state/tryon_gallery_provider.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/state/tryon_outcome.dart';
import 'package:tryzeon/feature/personal/tryon/providers/tryon_providers.dart';
import 'package:tryzeon/feature/personal/usage/providers/daily_usage_providers.dart';
import 'package:typed_result/typed_result.dart';
import 'package:uuid/uuid.dart';

part 'tryon_controller.g.dart';

@Riverpod(keepAlive: true)
class TryonController extends _$TryonController {
  static const _uuid = Uuid();
  int _seq = 0;

  @override
  TryonOutcomeEvent? build() => null;

  /// Runs an image try-on from a locally picked garment photo.
  Future<void> tryonFromLocalImage(final File image) async {
    final Uint8List bytes;
    try {
      bytes = await image.readAsBytes();
    } catch (e, stackTrace) {
      AppLogger.error('Failed to read picked garment image', e, stackTrace);
      return _emit(TryonFailed(mapExceptionToFailure(e)));
    }

    await _runTryon(
      garments: [
        TryonGarment(images: [TryonImageSource.base64(base64Encode(bytes))]),
      ],
      mode: TryonMode.image,
    );
  }

  /// Runs a try-on from garment images already stored remotely (by path).
  ///
  /// [garmentDetail] is an optional model-facing description of the garment's
  /// physical properties (e.g. from a shop product) threaded into the prompt.
  Future<void> tryonFromStoragePaths(
    final List<String> clothesPaths, {
    final TryonMode mode = TryonMode.image,
    final String? garmentDetail,
  }) {
    return _runTryon(
      garments: [
        TryonGarment(
          images: clothesPaths.map(TryonImageSource.path).toList(),
          detail: garmentDetail,
        ),
      ],
      mode: mode,
    );
  }

  void _emit(final TryonOutcome outcome) => state = TryonOutcomeEvent(_seq++, outcome);

  Future<void> _runTryon({
    required final List<TryonGarment> garments,
    required final TryonMode mode,
  }) async {
    final galleryNotifier = ref.read(tryonGalleryProvider.notifier);
    String? requestId;
    try {
      final customAvatarUrl = ref.read(tryonGalleryProvider).customAvatarResult?.imageUrl;
      final profile = await ref.read(userProfileProvider.future);
      final profileAvatarPath = profile?.avatarPath;

      // Precondition: "no avatar at all" is a UI prompt, not a failure — check
      // it before inserting a placeholder so nothing flickers.
      final hasAvatar =
          (customAvatarUrl != null && customAvatarUrl.isNotEmpty) ||
          (profileAvatarPath != null && profileAvatarPath.isNotEmpty);
      if (!hasAvatar) return _emit(const TryonAvatarMissing());

      String? scenePrompt;
      String? transitionPrompt;
      if (mode == TryonMode.video) {
        final promptConfig = await ref.read(videoPromptConfigProvider.future);
        scenePrompt = promptConfig.scenePrompt;
        transitionPrompt = promptConfig.transitionPrompt;
      }

      final id = requestId = _uuid.v4();
      galleryNotifier.addPending(id: id, mode: mode);

      final avatarResult = await ref.read(resolveTryonAvatarUseCaseProvider)(
        customAvatarUrl: customAvatarUrl,
        profileAvatarPath: profileAvatarPath,
      );
      if (avatarResult.isFailure) {
        galleryNotifier.removeById(id);
        return _emit(TryonFailed(avatarResult.getError()!));
      }

      final result = await ref.read(tryonUseCaseProvider)(
        TryonRequest(
          requestId: id,
          garments: garments,
          mode: mode,
          avatar: avatarResult.get()!,
          scenePrompt: scenePrompt,
          transitionPrompt: transitionPrompt,
        ),
      );

      final usageCache = ref.read(dailyUsageTodayProvider.notifier);
      if (result.isSuccess) {
        final tryonResult = result.get()!;
        usageCache.syncFromSnapshot(tryonResult.usage);
        galleryNotifier.complete(tryonResult);
        _emit(const TryonSucceeded());
      } else {
        final failure = result.getError()!;
        usageCache.syncFromFailure(failure);
        galleryNotifier.removeById(id);
        _emit(
          failure is RateLimitFailure
              ? TryonRateLimited(isVideo: mode == TryonMode.video)
              : TryonFailed(failure),
        );
      }
    } catch (e, stackTrace) {
      AppLogger.error('Try-on orchestration failed unexpectedly', e, stackTrace);
      final id = requestId;
      if (id != null) galleryNotifier.removeById(id);
      _emit(TryonFailed(mapExceptionToFailure(e)));
    }
  }
}
