/// Public API of the usage feature.
///
/// Other features depend on this barrel — never on `usage/data/**` internals.
/// The live usage cache is the separate `dailyUsageTodayProvider`; push decoded
/// snapshots into it via its `updateFromResponse` / `updateFromPayload` methods.
library;

export 'data/daily_usage_payload.dart';
export 'domain/entities/daily_usage.dart';
