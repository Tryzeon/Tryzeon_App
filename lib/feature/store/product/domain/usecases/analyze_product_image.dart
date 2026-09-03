import 'dart:io';

import 'package:tryzeon/core/utils/app_logger.dart';
import 'package:tryzeon/feature/store/product/domain/entities/product_analysis_result.dart';
import 'package:tryzeon/feature/store/product/domain/services/product_image_analyzer.dart';

class AnalyzeProductImage {
  AnalyzeProductImage(this._analyzer);

  final ProductImageAnalyzer _analyzer;

  Future<ProductAnalysisResult> call(final File image) async {
    try {
      return await _analyzer.analyze(image);
    } catch (e, st) {
      AppLogger.warning('product image analysis failed', e, st);
      return const ProductAnalysisResult();
    }
  }
}
