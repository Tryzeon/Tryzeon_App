import 'package:cached_query_flutter/cached_query_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProductTypeService {
  static final _supabase = Supabase.instance.client;
  static const _typesTable = 'product_types';

  static Query<List<String>> productTypesQuery() {
    return Query<List<String>>(
      key: ['product_types'],
      queryFn: fetchProductTypes,
      config: QueryConfig(storageDeserializer: (final json) => List<String>.from(json)),
    );
  }

  static Future<List<String>> fetchProductTypes() async {
    final response = await _supabase
        .from(_typesTable)
        .select('name_zh')
        .order('priority', ascending: true);

    return (response as List).map((final item) => item['name_zh'] as String).toList();
  }
}
