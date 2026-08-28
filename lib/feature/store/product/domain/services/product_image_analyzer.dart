import 'dart:io';

import 'package:tryzeon/feature/store/product/domain/entities/product_analysis_result.dart';

abstract interface class ProductImageAnalyzer {
  Future<ProductAnalysisResult> analyze(final File image);
}
