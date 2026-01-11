import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/feature/common/product_type/data/models/product_type_model.dart';

class ProductTypeRemoteDataSource {
  ProductTypeRemoteDataSource(this._supabaseClient);

  final SupabaseClient _supabaseClient;
  static const _table = 'product_categories';

  Future<List<ProductTypeModel>> fetchProductTypes() async {
    final response = await _supabaseClient
        .from(_table)
        .select('name_zh')
        .eq('is_active', true)
        .order('priority', ascending: true);

    return (response as List)
        .map((final e) => ProductTypeModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
