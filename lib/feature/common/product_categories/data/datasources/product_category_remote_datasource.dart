import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/core/config/app_constants.dart';
import 'package:tryzeon/core/config/env.dart';
import 'package:tryzeon/feature/common/product_categories/data/models/product_category_model.dart';

class ProductCategoryRemoteDataSource {
  ProductCategoryRemoteDataSource(this._supabaseClient);

  final SupabaseClient _supabaseClient;
  static const _productCategoryTable = AppConstants.tableProductCategories;

  Future<List<ProductCategoryModel>> getProductCategories() async {
    final response = await _supabaseClient
        .from(_productCategoryTable)
        .select('id, name, gender, wardrobe_category, image_path')
        .order('priority', ascending: false);

    return (response as List)
        .map((final e) => ProductCategoryModel.fromJson(_withCategoryImageUrl(e)))
        .toList();
  }

  Map<String, dynamic> _withCategoryImageUrl(final Map<String, dynamic> json) {
    final map = Map<String, dynamic>.from(json);
    final imagePath = map['image_path'] as String?;
    if (imagePath != null && imagePath.isNotEmpty) {
      map['image_url'] = '${Env.r2PublicImagesBaseUrl}/$imagePath';
    }
    return map;
  }
}
