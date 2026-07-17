import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/utils/app_logger.dart';
import 'package:tryzeon/feature/personal/home/presentation/state/try_on_outcome.dart';
import 'package:tryzeon/feature/personal/home/providers/tryon_gallery_provider.dart';
import 'package:tryzeon/feature/personal/profile/providers/personal_profile_providers.dart';
import 'package:tryzeon/feature/personal/settings/providers/settings_providers.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_garment.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_image_source.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_mode.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_params.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_result.dart';
import 'package:tryzeon/feature/personal/tryon/providers/tryon_providers.dart';
import 'package:typed_result/typed_result.dart';

part 'home_controller.g.dart';

/// Orchestrates the home screen's async actions — avatar upload and try-on —
/// keeping network, encoding, and gallery bookkeeping out of the page's
/// `build()`. UI reactions (dialogs, notifications, haptics) are driven by the
/// [TryOnOutcome] this returns.
///
/// `keepAlive: true` because it is invoked via `ref.read` (no long-lived
/// listener); without it autoDispose could tear it down mid-await.
@Riverpod(keepAlive: true)
class HomeController extends _$HomeController {
  @override
  void build() {}

  /// Uploads a new profile avatar and refreshes the profile/avatar caches.
  Future<Result<void, Failure>> uploadAvatar(final File image) async {
    try {
      final profile = await ref.read(userProfileProvider.future);
      if (profile == null) return const Ok(null);

      final result = await ref.read(updateUserAvatarUseCaseProvider)(
        avatarFile: image,
        previousAvatarPath: profile.avatarPath,
      );

      if (result.isSuccess) {
        ref.invalidate(userProfileProvider);
        ref.invalidate(avatarFileProvider);
        await ref.read(avatarFileProvider.future);
      }
      return result;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to upload avatar', e, stackTrace);
      return Err(mapExceptionToFailure(e));
    }
  }

  /// Runs an image try-on from a locally picked garment photo.
  Future<TryOnOutcome> tryOnFromLocalImage(final File image) async {
    final bytes = await image.readAsBytes();
    return _runTryOn(
      garments: [
        TryOnGarment(images: [TryOnImageSource.base64(base64Encode(bytes))]),
      ],
      mode: TryOnMode.image,
    );
  }

  /// Runs a try-on from garment images already stored remotely (by path).
  ///
  /// [garmentDetail] is an optional model-facing description of the garment's
  /// physical properties (e.g. from a shop product) threaded into the prompt.
  Future<TryOnOutcome> tryOnFromStoragePaths(
    final List<String> clothesPaths, {
    final TryOnMode mode = TryOnMode.image,
    final String? garmentDetail,
  }) {
    return _runTryOn(
      garments: [
        TryOnGarment(
          images: clothesPaths.map(TryOnImageSource.path).toList(),
          detail: garmentDetail,
        ),
      ],
      mode: mode,
    );
  }

  Future<TryOnOutcome> _runTryOn({
    required final List<TryOnGarment> garments,
    required final TryOnMode mode,
  }) async {
    final gallery = ref.read(tryonGalleryProvider);
    final galleryNotifier = ref.read(tryonGalleryProvider.notifier);
    final profile = await ref.read(userProfileProvider.future);

    final avatarResult = await ref.read(prepareTryonAvatarSourceUseCaseProvider)(
      customAvatarUrl: gallery.customAvatarResult?.imageUrl,
      profileAvatarPath: profile?.avatarPath,
    );
    if (avatarResult.isFailure) {
      return const TryOnAvatarLoadFailed();
    }
    final avatar = avatarResult.get();
    if (avatar == null) {
      return const TryOnAvatarMissing();
    }

    final requestId = UniqueKey().toString();
    galleryNotifier.addPlaceholder(
      TryonResult(id: requestId, mode: mode, isLoading: true),
    );

    String? scenePrompt;
    String? transitionPrompt;
    if (mode == TryOnMode.video) {
      final promptConfig = await ref.read(videoPromptConfigProvider.future);
      scenePrompt = promptConfig.scenePrompt;
      transitionPrompt = promptConfig.transitionPrompt;
    }

    final result = await ref
        .read(tryonActionProvider.notifier)
        .execute(
          TryOnParams(
            requestId: requestId,
            avatar: avatar,
            garments: garments,
            mode: mode,
            scenePrompt: scenePrompt,
            transitionPrompt: transitionPrompt,
          ),
        );

    if (result.isSuccess) {
      galleryNotifier.replaceById(requestId, result.get()!.copyWith(isLoading: false));
      return const TryOnSucceeded();
    }

    galleryNotifier.removeById(requestId);
    final failure = result.getError()!;
    if (failure is RateLimitFailure) {
      return TryOnRateLimited(isVideo: mode == TryOnMode.video);
    }
    return TryOnFailed(failure);
  }
}
