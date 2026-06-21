import 'dart:convert';
import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'image_analysis_api.g.dart';

/// Shared transport for single-image AI analysis Edge Functions: compresses the
/// image, base64-encodes it, invokes [functionName], and returns the decoded
/// JSON body (or null on any failure — callers degrade gracefully).
class ImageAnalysisApi {
  ImageAnalysisApi(this._supabase);

  final SupabaseClient _supabase;

  static const _timeout = Duration(seconds: 20);

  Future<Map<String, dynamic>?> analyze({
    required final File image,
    required final String functionName,
  }) async {
    final jpeg = await FlutterImageCompress.compressWithFile(
      image.path,
      minWidth: 768,
      minHeight: 768,
      quality: 80,
      format: CompressFormat.jpeg,
    );
    if (jpeg == null) return null;

    final base64Image = base64Encode(jpeg);
    final response = await _supabase.functions
        .invoke(functionName, body: {'base64': base64Image})
        .timeout(_timeout);

    final data = response.data;
    return data is Map<String, dynamic> ? data : null;
  }
}

@Riverpod(keepAlive: true)
ImageAnalysisApi imageAnalysisApi(final Ref ref) =>
    ImageAnalysisApi(Supabase.instance.client);
