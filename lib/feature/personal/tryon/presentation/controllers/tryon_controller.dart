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

  @override
  TryonOutcome? build() => null;

  /// One-shot event lane: two identical outcomes in a row (e.g. two consecutive
  /// successes, which Dart canonicalizes to the same `const` instance) must both
  /// reach `ref.listen`, so every assignment notifies.
  @override
  bool updateShouldNotify(final TryonOutcome? previous, final TryonOutcome? next) => true;

  /// Runs a try-on from a locally picked garment photo.
  Future<void> tryonFromLocalImage(
    final File image, {
    final TryonMode mode = TryonMode.image,
  }) async {
    final Uint8List bytes;
    try {
      bytes = await image.readAsBytes();
    } catch (e, stackTrace) {
      AppLogger.error('Failed to read picked garment image', e, stackTrace);
      state = TryonFailed(mapExceptionToFailure(e));
      return;
    }

    await _runTryon(
      garments: [
        TryonGarment.images(images: [TryonImageSource.base64(base64Encode(bytes))]),
      ],
      mode: mode,
    );
  }

  /// Runs a try-on from garment images already stored remotely (by path).
  Future<void> tryonFromStoragePaths(
    final List<String> garmentImagePaths, {
    final TryonMode mode = TryonMode.image,
  }) {
    return _runTryon(
      garments: [
        TryonGarment.images(
          images: garmentImagePaths.map(TryonImageSource.path).toList(),
        ),
      ],
      mode: mode,
    );
  }

  /// Runs a try-on for a catalog product; the backend resolves its garment
  /// image and prompt detail from the product id.
  Future<void> tryonFromProduct(
    final String productId, {
    final TryonMode mode = TryonMode.image,
  }) {
    return _runTryon(
      garments: [TryonGarment.product(productId: productId)],
      mode: mode,
    );
  }

  Future<void> _runTryon({
    required final List<TryonGarment> garments,
    required final TryonMode mode,
  }) async {
    final galleryNotifier = ref.read(tryonGalleryProvider.notifier);
    final id = _uuid.v4();
    try {
      final customAvatarUrl = ref.read(tryonGalleryProvider).customAvatarResult?.imageUrl;
      final hasCustomAvatar = customAvatarUrl != null && customAvatarUrl.isNotEmpty;

      // Precondition: "no avatar at all" is a UI prompt, not a failure — check
      // it before inserting a placeholder so nothing flickers. The backend
      // answers NO_AVATAR either way, so this only saves a round trip.
      final profile = await ref.read(userProfileProvider.future);
      if (!hasCustomAvatar && !(profile?.avatarPath?.isNotEmpty ?? false)) {
        state = const TryonAvatarMissing();
        return;
      }

      // Scene applies to both modes — video renders its first frame through the
      // same image pass. Transition only reaches the video generator.
      final promptConfig = await ref.read(tryonPromptConfigProvider.future);

      galleryNotifier.addPending(id: id, mode: mode);

      final customAvatarBase64 = await ref.read(loadCustomAvatarUseCaseProvider)(
        customAvatarUrl,
      );
      if (customAvatarBase64.isFailure) {
        galleryNotifier.removeById(id);
        state = TryonFailed(customAvatarBase64.getError()!);
        return;
      }

      final result = await ref.read(tryonUseCaseProvider)(
        TryonRequest(
          requestId: id,
          garments: garments,
          mode: mode,
          avatarBase64: customAvatarBase64.get(),
          scenePrompt: promptConfig.scenePrompt,
          transitionPrompt: mode == TryonMode.video
              ? promptConfig.transitionPrompt
              : null,
        ),
      );

      final usageCache = ref.read(dailyUsageTodayProvider.notifier);
      if (result.isSuccess) {
        final tryonResult = result.get()!;
        usageCache.syncFromSnapshot(tryonResult.usage);
        galleryNotifier.complete(tryonResult);
        state = const TryonSucceeded();
      } else {
        final failure = result.getError()!;
        usageCache.syncFromFailure(failure);
        galleryNotifier.removeById(id);
        state = switch (failure) {
          RateLimitFailure() => TryonRateLimited(isVideo: mode == TryonMode.video),
          AvatarMissingFailure() => const TryonAvatarMissing(),
          _ => TryonFailed(failure),
        };
      }
    } catch (e, stackTrace) {
      AppLogger.error('Try-on orchestration failed unexpectedly', e, stackTrace);
      galleryNotifier.removeById(id);
      state = TryonFailed(mapExceptionToFailure(e));
    }
  }
}
