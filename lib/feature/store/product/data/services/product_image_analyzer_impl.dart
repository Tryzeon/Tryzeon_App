import 'dart:io';

import 'package:tryzeon/core/config/app_constants.dart';
import 'package:tryzeon/core/data/services/image_analysis_api.dart';
import 'package:tryzeon/feature/common/clothing_style/domain/entities/clothing_style.dart';
import 'package:tryzeon/feature/common/product_attributes/domain/entities/product_attributes.dart';
import 'package:tryzeon/feature/store/product/domain/entities/product_analysis_result.dart';
import 'package:tryzeon/feature/store/product/domain/services/product_image_analyzer.dart';

String? _str(final dynamic v) => v is String && v.trim().isNotEmpty ? v.trim() : null;

List<String> _strList(final dynamic v) => v is List
    ? v.whereType<String>().where((final s) => s.isNotEmpty).toList()
    : const <String>[];

ProductAnalysisResult parseProductAnalysisResponse(final Map<String, dynamic> data) {
  return ProductAnalysisResult(
    name: _str(data['name']),
    categoryId: _str(data['categoryId']),
    gender: ProductGender.tryFromString(_str(data['gender'])),
    styles: ClothingStyle.listFromStrings(_strList(data['styles'])) ?? const [],
    seasons: ProductSeason.listFromStrings(_strList(data['seasons'])) ?? const [],
    material: _str(data['material']),
    fit: ProductFit.tryFromString(_str(data['fit'])),
    thickness: ProductThickness.tryFromString(_str(data['thickness'])),
    elasticity: ProductElasticity.tryFromString(_str(data['elasticity'])),
  );
}

class ProductImageAnalyzerImpl implements ProductImageAnalyzer {
  ProductImageAnalyzerImpl(this._api);

  final ImageAnalysisApi _api;

  @override
  Future<ProductAnalysisResult> analyze(final File image) async {
    final data = await _api.analyze(
      image: image,
      functionName: AppConstants.functionAnalyzeProductImage,
    );
    if (data == null) return const ProductAnalysisResult();
    return parseProductAnalysisResponse(data);
  }
}
