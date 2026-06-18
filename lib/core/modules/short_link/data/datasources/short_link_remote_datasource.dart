import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/core/config/app_constants.dart';

/// Destination a short link resolves to.
class LinkTarget {
  const LinkTarget({required this.targetType, required this.targetId});

  /// 'product' or 'store'.
  final String targetType;
  final String targetId;
}

class ShortLinkRemoteDataSource {
  ShortLinkRemoteDataSource(this._supabaseClient);

  final SupabaseClient _supabaseClient;

  /// Records an identified link open (the user is authenticated) and resolves
  /// the code to its destination so the caller can navigate.
  ///
  /// [source] is 'app' for an installed open or 'deferred' for an open
  /// delivered by the platform SDK after a deferred install.
  ///
  /// Returns `null` when the code is unknown or inactive.
  Future<LinkTarget?> recordOpen({
    required final String code,
    required final String platform,
    required final String source,
  }) async {
    final response =
        await _supabaseClient.rpc(
              AppConstants.functionRecordLinkOpen,
              params: {'p_code': code, 'p_platform': platform, 'p_source': source},
            )
            as List<dynamic>;

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
