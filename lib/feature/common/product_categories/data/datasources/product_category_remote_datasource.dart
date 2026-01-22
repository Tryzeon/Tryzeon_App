import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/core/config/app_constants.dart';
import 'package:tryzeon/feature/common/product_categories/data/models/product_category_model.dart';

class ProductCategoryRemoteDataSource {
  ProductCategoryRemoteDataSource(this._supabaseClient);

  final SupabaseClient _supabaseClient;
  static const _table = AppConstants.tableProductCategories;

  Future<List<ProductCategoryModel>> fetchProductCategories() async {
    final response = await _supabaseClient
        .from(_table)
        .select('id, name')
        .eq('is_active', true)
        .order('priority', ascending: true);

    return (response as List)
        .map((final e) => ProductCategoryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
