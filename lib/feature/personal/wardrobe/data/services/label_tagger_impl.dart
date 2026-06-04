import 'dart:convert';
import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/core/config/app_constants.dart';
import 'package:tryzeon/feature/common/product_attributes/entities/wardrobe_category.dart';

import '../../domain/entities/label_result.dart';
import '../../domain/services/label_tagger.dart';

LabelResult parseAnalysisResponse(final Map<String, dynamic> data) {
  final rawTags = data['tags'];
  final tags = rawTags is List
      ? rawTags.whereType<String>().where((final t) => t.isNotEmpty).toList()
      : <String>[];

  final rawCategory = data['category'];
  final category = rawCategory is String
      ? WardrobeCategory.tryFromString(rawCategory)
      : null;

  return LabelResult(tags: tags, category: category);
}

class LabelTaggerImpl implements LabelTagger {
  LabelTaggerImpl(this._supabase);

  final SupabaseClient _supabase;

  static const _analysisTimeout = Duration(seconds: 20);

  @override
  Future<LabelResult> analyze(final File image) async {
    final jpeg = await FlutterImageCompress.compressWithFile(
      image.path,
      minWidth: 768,
      minHeight: 768,
      quality: 80,
      format: CompressFormat.jpeg,
    );
    if (jpeg == null) return const LabelResult();

    final base64Image = base64Encode(jpeg);
    final response = await _supabase.functions
        .invoke(
          AppConstants.functionAnalyzeWardrobeImage,
          body: {'base64': base64Image},
        )
        .timeout(_analysisTimeout);
    final data = response.data;
    if (data is! Map<String, dynamic>) return const LabelResult();
    return parseAnalysisResponse(data);
  }
}
