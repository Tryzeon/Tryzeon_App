import 'package:tryzeon/core/config/app_constants.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_garment.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_mode.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_request.dart';

/// Client → Server wire body for the `tryon` edge function.
///
/// Owns the domain → wire serialization (built once via [TryonRequestModel.fromDomain])
/// so the datasource stays pure transport and never imports domain entities.
/// Hand-written rather than json_serializable because the body omits empty
/// prompts, an absent avatar and an absent garment list, and wraps each garment
/// image as `{base64}`.
class TryonRequestModel {
  const TryonRequestModel({
    required this.garments,
    required this.mode,
    required this.isVideo,
    required this.engine,
    this.avatarBase64,
    this.baseImageBase64,
    this.scenePrompt,
    this.stylingPrompt,
    this.transitionPrompt,
  });

  factory TryonRequestModel.fromDomain(final TryonRequest request) {
    return switch (request) {
      TryonGenerateRequest(
        :final garments,
        :final mode,
        :final avatarBase64,
        :final scenePrompt,
        :final stylingPrompt,
        :final transitionPrompt,
        :final engine,
      ) =>
        TryonRequestModel(
          avatarBase64: avatarBase64,
          garments: garments.map(_garmentToJson).toList(),
          mode: mode.name,
          isVideo: mode == TryonMode.video,
          scenePrompt: scenePrompt,
          stylingPrompt: stylingPrompt,
          transitionPrompt: transitionPrompt,
          engine: engine.name,
        ),
      // The backend rejects an animate body carrying garments or an avatar and
      // drops a scene or styling prompt, so none of them are ever set here.
      TryonAnimateRequest(
        :final baseImageBase64,
        :final transitionPrompt,
        :final engine,
      ) =>
        TryonRequestModel(
          garments: const [],
          mode: AppConstants.modeVideo,
          isVideo: true,
          baseImageBase64: baseImageBase64,
          transitionPrompt: transitionPrompt,
          engine: engine.name,
        ),
    };
  }

  final String? avatarBase64;
  final String? baseImageBase64;
  final List<Map<String, Object>> garments;
  final String mode;
  final bool isVideo;
  final String engine;
  final String? scenePrompt;
  final String? stylingPrompt;
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
    final styling = stylingPrompt;
    if (styling != null && styling.isNotEmpty) {
      body[AppConstants.paramStylingPrompt] = styling;
    }
    final transition = transitionPrompt;
    if (transition != null && transition.isNotEmpty) {
      body[AppConstants.paramTransitionPrompt] = transition;
    }
    body[AppConstants.paramEngine] = engine;
    return body;
  }

  static Map<String, Object> _garmentToJson(final TryonGarment garment) {
    return switch (garment) {
      TryonGarmentProduct(:final productId, :final sizeId) => {
        AppConstants.paramProductId: productId,
        AppConstants.paramSizeId: ?sizeId,
      },
      TryonGarmentWardrobe(:final wardrobeItemId) => {
        AppConstants.paramWardrobeItemId: wardrobeItemId,
      },
      TryonGarmentImages(:final base64Images) => {
        AppConstants.paramGarmentImages: base64Images
            .map((final data) => {'base64': data})
            .toList(),
      },
    };
  }
}
