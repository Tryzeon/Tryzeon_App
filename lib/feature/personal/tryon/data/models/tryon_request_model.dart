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
/// prompts and encodes polymorphic image sources as `{path}` / `{base64}`.
class TryonRequestModel {
  const TryonRequestModel({
    required this.avatar,
    required this.garments,
    required this.mode,
    required this.isVideo,
    this.scenePrompt,
    this.transitionPrompt,
  });

  /// Maps a domain [request] (avatar already resolved) into the wire model.
  factory TryonRequestModel.fromDomain(final TryonRequest request) {
    return TryonRequestModel(
      avatar: _sourceToJson(request.avatar),
      garments: request.garments.map(_garmentToJson).toList(),
      mode: request.mode.name,
      isVideo: request.mode == TryonMode.video,
      scenePrompt: request.scenePrompt,
      transitionPrompt: request.transitionPrompt,
    );
  }

  final Map<String, String> avatar;
  final List<Map<String, Object>> garments;
  final String mode;
  final bool isVideo;
  final String? scenePrompt;
  final String? transitionPrompt;

  Map<String, dynamic> toJson() {
    final body = <String, dynamic>{
      'avatar': avatar,
      'garments': garments,
      AppConstants.paramMode: mode,
    };
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
    final json = <String, Object>{
      AppConstants.paramGarmentImages: garment.images.map(_sourceToJson).toList(),
    };
    final detail = garment.detail;
    if (detail != null && detail.isNotEmpty) {
      json[AppConstants.paramGarmentDetail] = detail;
    }
    return json;
  }
}
