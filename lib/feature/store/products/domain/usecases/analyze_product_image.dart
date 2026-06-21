import 'dart:io';

import 'package:tryzeon/core/utils/app_logger.dart';
import 'package:tryzeon/feature/store/products/domain/entities/product_analysis_result.dart';
import 'package:tryzeon/feature/store/products/domain/services/product_image_analyzer.dart';

/// Analyzes a product image, degrading to an empty result on any failure so
/// product creation is never blocked.
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
