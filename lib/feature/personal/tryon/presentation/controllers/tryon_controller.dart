import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/utils/app_logger.dart';
import 'package:tryzeon/feature/auth/providers/auth_providers.dart';
import 'package:tryzeon/feature/personal/profile/providers/personal_profile_providers.dart';
import 'package:tryzeon/feature/personal/settings/domain/entities/tryon_preferences.dart';
import 'package:tryzeon/feature/personal/settings/providers/settings_providers.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_garment.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_image_source.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_mode.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_request.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_subject.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/state/tryon_gallery_entry.dart';
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
  TryonOutcome? build() {
    ref.watch(isAuthenticatedProvider);
    return null;
  }

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

    await _start(
      TryonSubject.generate(
        garments: [
          TryonGarment.images(images: [TryonImageSource.base64(base64Encode(bytes))]),
        ],
        mode: mode,
      ),
    );
  }

  /// Runs a try-on from garment images already stored remotely (by path).
  Future<void> tryonFromStoragePaths(
    final List<String> garmentImagePaths, {
    final TryonMode mode = TryonMode.image,
  }) {
    return _start(
      TryonSubject.generate(
        garments: [
          TryonGarment.images(
            images: garmentImagePaths.map(TryonImageSource.path).toList(),
          ),
        ],
        mode: mode,
      ),
    );
  }

  /// Runs a try-on for a catalog product; the backend resolves its garment
  /// image and prompt detail from the product id. [sizeId] names the size being
  /// worn, when the shopper's measurements yielded a recommendation.
  Future<void> tryonFromProduct(
    final String productId, {
    final String? sizeId,
    final TryonMode mode = TryonMode.image,
  }) {
    return _start(
      TryonSubject.generate(
        garments: [TryonGarment.product(productId: productId, sizeId: sizeId)],
        mode: mode,
      ),
    );
  }

  /// Runs [entry] again. The preferences are read fresh, so a style or engine
  /// changed since is the one that applies.
  Future<void> regenerate(final TryonGalleryEntry entry) => _start(entry.subject);

  /// The video lands as a new gallery entry, leaving the original photo there
  /// to download or set as the model. Image generation is skipped entirely, so
  /// the scene and styling prompts have nothing left to influence and only the
  /// transition style shapes the result — the engine travels anyway, against
  /// the day a video model has tiers of its own.
  ///
  /// Takes the entry, not its result: the video inherits its subject.
  Future<void> animate(final FinishedTryonEntry entry) async {
    final imageUrl = entry.result.imageUrl;
    if (entry.mode != TryonMode.image || imageUrl == null || imageUrl.isEmpty) {
      state = const TryonFailed(ValidationFailure());
      return;
    }

    await _start(
      TryonSubject.animated(baseImageUrl: imageUrl, origin: entry.subject),
    );
  }

  /// The one path every try-on takes.
  Future<void> _start(final TryonSubject subject) async {
    // Setup runs before the placeholder exists, so its failures always speak up.
    String? customAvatarUrl;
    final TryonPreferences preferences;
    try {
      // An animate job dresses a finished picture, so it needs no avatar.
      if (subject is TryonSubjectGenerate) {
        customAvatarUrl = ref.read(tryonGalleryProvider).customAvatarResult?.imageUrl;
        final hasCustomAvatar = customAvatarUrl != null && customAvatarUrl.isNotEmpty;

        // Precondition: "no avatar at all" is a UI prompt, not a failure — check
        // it before inserting a placeholder so nothing flickers. The backend
        // answers NO_AVATAR either way, so this only saves a round trip.
        final profile = await ref.read(userProfileProvider.future);
        if (!hasCustomAvatar && !(profile?.avatarPath?.isNotEmpty ?? false)) {
          state = const TryonAvatarMissing();
          return;
        }
      }

      // Scene and styling apply to both modes — video renders its first frame
      // through the same image pass. Transition only reaches the video
      // generator.
      preferences = await ref.read(tryonPreferencesProvider.future);
    } catch (e, stackTrace) {
      AppLogger.error('Try-on setup failed', e, stackTrace);
      state = TryonFailed(mapExceptionToFailure(e));
      return;
    }

    final galleryNotifier = ref.read(tryonGalleryProvider.notifier);
    final id = _uuid.v4();

    // Before the request is built, because building it fetches images.
    galleryNotifier.addPending(id: id, subject: subject);

    // Past the placeholder everything recovers the same way. A `removeById`
    // that finds nothing means the user cancelled, so that run stays silent.
    try {
      final request = await _buildRequest(
        id: id,
        subject: subject,
        preferences: preferences,
        customAvatarUrl: customAvatarUrl,
      );
      if (request.isFailure) {
        if (!galleryNotifier.removeById(id)) return;
        state = TryonFailed(request.getError()!);
        return;
      }

      final result = await ref.read(tryonUseCaseProvider)(request.get()!);

      // Usage syncs even for a cancelled run — the generation was still spent.
      final usageCache = ref.read(dailyUsageTodayProvider.notifier);
      if (result.isSuccess) {
        final tryonResult = result.get()!;
        usageCache.syncFromSnapshot(tryonResult.usage);
        if (!galleryNotifier.complete(tryonResult)) return;
        state = const TryonSucceeded();
      } else {
        final failure = result.getError()!;
        usageCache.syncFromFailure(failure);
        if (!galleryNotifier.removeById(id)) return;
        state = switch (failure) {
          RateLimitFailure() => TryonRateLimited(
            isVideo: subject.mode == TryonMode.video,
          ),
          AvatarMissingFailure() => const TryonAvatarMissing(),
          _ => TryonFailed(failure),
        };
      }
    } catch (e, stackTrace) {
      AppLogger.error('Try-on orchestration failed unexpectedly', e, stackTrace);
      if (!galleryNotifier.removeById(id)) return;
      state = TryonFailed(mapExceptionToFailure(e));
    }
  }

  /// Fallible because both variants fetch an image first, and a failure there
  /// must never reach the backend. Named parameters because [id] and
  /// [customAvatarUrl] are both strings and would transpose silently.
  Future<Result<TryonRequest, Failure>> _buildRequest({
    required final String id,
    required final TryonSubject subject,
    required final TryonPreferences preferences,
    required final String? customAvatarUrl,
  }) async {
    final loadImage = ref.read(loadImageAsBase64UseCaseProvider);

    switch (subject) {
      case TryonSubjectAnimated(:final baseImageUrl):
        final image = await loadImage(baseImageUrl);
        if (image.isFailure) return Err(image.getError()!);

        return Ok(
          TryonRequest.animate(
            requestId: id,
            baseImageBase64: image.get()!,
            transitionPrompt: preferences.transitionPrompt,
            engine: preferences.engine,
          ),
        );

      case TryonSubjectGenerate(:final garments, :final mode):
        // Sending none makes the backend fall back to the profile photo.
        String? avatarBase64;
        if (customAvatarUrl != null && customAvatarUrl.isNotEmpty) {
          final loaded = await loadImage(customAvatarUrl);
          if (loaded.isFailure) return Err(loaded.getError()!);
          avatarBase64 = loaded.get();
        }

        return Ok(
          TryonRequest.generate(
            requestId: id,
            garments: garments,
            mode: mode,
            avatarBase64: avatarBase64,
            scenePrompt: preferences.scenePrompt,
            stylingPrompt: preferences.stylingPrompt,
            transitionPrompt: mode == TryonMode.video
                ? preferences.transitionPrompt
                : null,
            engine: preferences.engine,
          ),
        );
    }
  }
}
