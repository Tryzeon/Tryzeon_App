import 'dart:io';

import 'package:tryzeon/core/config/app_constants.dart';
import 'package:tryzeon/core/data/services/image_analysis_api.dart';
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
  LabelTaggerImpl(this._api);

  final ImageAnalysisApi _api;

  @override
  Future<LabelResult> analyze(final File image) async {
    final data = await _api.analyze(
      image: image,
      functionName: AppConstants.functionAnalyzeWardrobeImage,
    );
    if (data == null) return const LabelResult();
    return parseAnalysisResponse(data);
  }
}
