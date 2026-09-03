import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/core/config/app_constants.dart';
import 'package:tryzeon/feature/store/analytics/data/models/product_analytics_summary_model.dart';

class ProductAnalyticsRemoteDataSource {
  ProductAnalyticsRemoteDataSource(this._supabaseClient);

  final SupabaseClient _supabaseClient;

  Future<List<ProductAnalyticsSummaryModel>> getProductAnalyticsSummaries(
    final String storeId, {
    required final int year,
    required final int month,
  }) async {
    final response = await _supabaseClient
        .from(AppConstants.tableAnalyticsProductMonthlySummary)
        .select()
        .eq('store_id', storeId)
        .eq('year', year)
        .eq('month', month);

    return response
        .map(
          (final e) =>
              ProductAnalyticsSummaryModel.fromJson(Map<String, dynamic>.from(e)),
        )
        .toList();
  }

  Future<List<ProductAnalyticsSummaryModel>> getAllProductAnalyticsSummaries(
    final String storeId,
  ) async {
    final response = await _supabaseClient
        .from(AppConstants.tableAnalyticsProductMonthlySummary)
        .select()
        .eq('store_id', storeId);

    return response
        .map(
          (final e) =>
              ProductAnalyticsSummaryModel.fromJson(Map<String, dynamic>.from(e)),
        )
        .toList();
  }
}
