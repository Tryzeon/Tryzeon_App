import 'package:tryzeon/feature/personal/usage/data/models/daily_usage_model.dart';
import 'package:tryzeon/feature/personal/usage/domain/entities/daily_usage.dart';

/// Decodes a raw `usage` snapshot into a [DailyUsage] entity.
///
/// The tryon and chat edge functions inline this snapshot in both success
/// bodies and 429 rate-limit payloads so the client can refresh the usage
/// cache without an extra round trip. This is the usage feature's published
/// decoder: other features route usage-payload decoding through here (exposed
/// via `usage/usage.dart`) instead of reaching into [DailyUsageModel], keeping
/// the wire format owned by this feature.
DailyUsage parseDailyUsagePayload(final Map<String, dynamic> json) =>
    DailyUsageModel.fromJson(json).toEntity();
