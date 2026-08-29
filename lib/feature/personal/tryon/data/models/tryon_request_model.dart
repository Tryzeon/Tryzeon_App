import 'package:tryzeon/core/config/app_constants.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_garment.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_image_source.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_mode.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_request.dart';

/// Client → Server wire body for the `tryon` edge function.
///
/// Owns the domain → wire serialization (built once via [TryonRequestModel.fromDomain])
/// so the datasource stays pure transport and never imports domain entities.
/// Hand-written rather than json_serializable because the body omits empty
/// prompts, an absent avatar and an absent garment list, and encodes garment
/// image sources as `{path}` / `{base64}`.
class TryonRequestModel {
  const TryonRequestModel({
    required this.garments,
    required this.mode,
    required this.isVideo,
    this.avatarBase64,
    this.baseImageBase64,
    this.scenePrompt,
    this.transitionPrompt,
  });

  /// Maps a domain [request] into the wire model.
  factory TryonRequestModel.fromDomain(final TryonRequest request) {
    return switch (request) {
      TryonGenerateRequest(
        :final garments,
        :final mode,
        :final avatarBase64,
        :final scenePrompt,
        :final transitionPrompt,
      ) =>
        TryonRequestModel(
          avatarBase64: avatarBase64,
          garments: garments.map(_garmentToJson).toList(),
          mode: mode.name,
          isVideo: mode == TryonMode.video,
          scenePrompt: scenePrompt,
          transitionPrompt: transitionPrompt,
        ),
      // The backend rejects an animate body carrying garments, an avatar or a
      // scene prompt, so none of them are ever set here.
      TryonAnimateRequest(:final baseImageBase64, :final transitionPrompt) =>
        TryonRequestModel(
          garments: const [],
          mode: AppConstants.modeVideo,
          isVideo: true,
          baseImageBase64: baseImageBase64,
          transitionPrompt: transitionPrompt,
        ),
    };
  }

  final String? avatarBase64;
  final String? baseImageBase64;
  final List<Map<String, Object>> garments;
  final String mode;
  final bool isVideo;
  final String? scenePrompt;
  final String? transitionPrompt;

  Map<String, dynamic> toJson() {
    final body = <String, dynamic>{AppConstants.paramMode: mode};
    if (garments.isNotEmpty) {
      body['garments'] = garments;
    }
    final baseImage = baseImageBase64;
    if (baseImage != null && baseImage.isNotEmpty) {
      body[AppConstants.paramBaseImage] = {'base64': baseImage};
    }
    final avatar = avatarBase64;
    if (avatar != null && avatar.isNotEmpty) {
      body['avatar'] = {'base64': avatar};
    }
    final scene = scenePrompt;
    if (scene != null && scene.isNotEmpty) {
      body[AppConstants.paramScenePrompt] = scene;
    }
    final transition = transitionPrompt;
    if (transition != null && transition.isNotEmpty) {
      body[AppConstants.paramTransitionPrompt] = transition;
    }
    return body;
  }

  static Map<String, String> _sourceToJson(final TryonImageSource source) {
    return switch (source) {
      TryonImageSourcePath(:final path) => {'path': path},
      TryonImageSourceBase64(:final data) => {'base64': data},
    };
  }

  static Map<String, Object> _garmentToJson(final TryonGarment garment) {
    return switch (garment) {
      TryonGarmentProduct(:final productId, :final sizeId) => {
        AppConstants.paramProductId: productId,
        AppConstants.paramSizeId: ?sizeId,
      },
      TryonGarmentImages(:final images) => {
        AppConstants.paramGarmentImages: images.map(_sourceToJson).toList(),
      },
    };
  }
}
