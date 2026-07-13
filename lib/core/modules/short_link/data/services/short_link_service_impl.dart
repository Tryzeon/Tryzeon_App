import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/core/config/app_constants.dart';
import 'package:tryzeon/core/modules/short_link/domain/entities/link_target.dart';
import 'package:tryzeon/core/modules/short_link/domain/services/short_link_service.dart';

/// [ShortLinkService] implementation backed by a Supabase RPC.
class ShortLinkServiceImpl implements ShortLinkService {
  ShortLinkServiceImpl(this._supabaseClient);

  final SupabaseClient _supabaseClient;

  @override
  Future<LinkTarget?> recordOpen({
    required final String code,
    required final String platform,
    required final String source,
  }) async {
    final response = await _supabaseClient.rpc<List<dynamic>>(
      AppConstants.functionRecordLinkOpen,
      params: {'p_code': code, 'p_platform': platform, 'p_source': source},
    );

    if (response.isEmpty) {
      return null;
    }

    final row = response.first as Map<String, dynamic>;
    return LinkTarget(
      targetType: row['target_type'] as String,
      targetId: row['target_id'] as String,
    );
  }
}
