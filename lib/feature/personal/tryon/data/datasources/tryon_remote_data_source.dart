import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/core/config/app_constants.dart';
import '../../domain/entities/tryon_garment.dart';
import '../../domain/entities/tryon_image_source.dart';
import '../../domain/entities/tryon_params.dart';

Map<String, String> _sourceToJson(final TryOnImageSource source) {
  return switch (source) {
    TryOnImageSourcePath(:final path) => {'path': path},
    TryOnImageSourceBase64(:final data) => {'base64': data},
  };
}

Map<String, Object> _garmentToJson(final TryOnGarment garment) {
  final json = <String, Object>{
    AppConstants.paramGarmentImages: garment.images.map(_sourceToJson).toList(),
  };
  final detail = garment.detail;
  if (detail != null && detail.isNotEmpty) {
    json[AppConstants.paramGarmentDetail] = detail;
  }
  return json;
}

/// Pure mapping from [TryOnParams] to the edge function wire body.
Map<String, dynamic> tryOnParamsToBody(final TryOnParams params) {
  final body = <String, dynamic>{
    'avatar': _sourceToJson(params.avatar),
    'garments': params.garments.map(_garmentToJson).toList(),
    AppConstants.paramMode: params.mode.name,
  };
  final scene = params.scenePrompt;
  if (scene != null && scene.isNotEmpty) {
    body[AppConstants.paramScenePrompt] = scene;
  }
  final transition = params.transitionPrompt;
  if (transition != null && transition.isNotEmpty) {
    body[AppConstants.paramTransitionPrompt] = transition;
  }
  return body;
}

class TryonRemoteDataSource {
  TryonRemoteDataSource(this._supabase);
  final SupabaseClient _supabase;

  Future<Map<String, dynamic>> tryon(final TryOnParams params) async {
    final response = await _supabase.functions.invoke(
      AppConstants.functionTryon,
      body: tryOnParamsToBody(params),
    );
    return response.data as Map<String, dynamic>;
  }
}
