import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/core/config/app_constants.dart';
import 'package:tryzeon/core/modules/analytics/data/models/analytics_event_model.dart';

class AnalyticsRemoteDataSource {
  AnalyticsRemoteDataSource(this._supabaseClient);

  final SupabaseClient _supabaseClient;

  Future<void> uploadAnalyticsEvents(final List<AnalyticsEventModel> events) async {
    if (events.isEmpty) {
      return;
    }

    final user = _supabaseClient.auth.currentUser;
    if (user == null) {
      return;
    }

    final eventsJson = events.map((final e) => e.toJson()).toList();

    await _supabaseClient.rpc<void>(
      AppConstants.functionLogAnalyticsEvents,
      params: {'p_events': eventsJson},
    );
  }
}
