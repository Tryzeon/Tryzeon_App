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
        .select('id, name, gender, wardrobe_category, image_male, image_female')
        .order('order', ascending: true);

    return (response as List)
        .map((final e) => ProductCategoryModel.fromJson(_withCategoryImageUrls(e)))
        .toList();
  }

  Map<String, dynamic> _withCategoryImageUrls(final Map<String, dynamic> json) {
    final map = Map<String, dynamic>.from(json);
    final male = map['image_male'] as String?;
    final female = map['image_female'] as String?;
    if (male != null && male.isNotEmpty) {
      map['image_male_url'] = '${Env.r2PublicImagesBaseUrl}/$male';
    }
    if (female != null && female.isNotEmpty) {
      map['image_female_url'] = '${Env.r2PublicImagesBaseUrl}/$female';
    }
    return map;
  }
}
