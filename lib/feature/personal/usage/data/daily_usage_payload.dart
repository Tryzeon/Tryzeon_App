import 'package:tryzeon/feature/personal/usage/data/models/daily_usage_model.dart';
import 'package:tryzeon/feature/personal/usage/domain/entities/daily_usage.dart';

/// The tryon and chat edge functions inline this snapshot in both success
/// bodies and 429 rate-limit payloads so the client can refresh the usage
/// cache without an extra round trip.
DailyUsage parseDailyUsagePayload(final Map<String, dynamic> json) =>
    DailyUsageModel.fromJson(json).toEntity();
