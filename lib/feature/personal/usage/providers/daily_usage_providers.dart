import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/personal/usage/data/daily_usage_payload.dart';
import 'package:tryzeon/feature/personal/usage/data/datasources/daily_usage_remote_datasource.dart';
import 'package:tryzeon/feature/personal/usage/data/repositories/daily_usage_repository_impl.dart';
import 'package:tryzeon/feature/personal/usage/domain/entities/daily_usage.dart';
import 'package:tryzeon/feature/personal/usage/domain/repositories/daily_usage_repository.dart';
import 'package:tryzeon/feature/personal/usage/domain/usecases/get_today_usage.dart';
import 'package:typed_result/typed_result.dart';

part 'daily_usage_providers.g.dart';

@riverpod
DailyUsageRemoteDataSource dailyUsageRemoteDataSource(final Ref ref) =>
    DailyUsageRemoteDataSource(Supabase.instance.client);

@riverpod
DailyUsageRepository dailyUsageRepository(final Ref ref) => DailyUsageRepositoryImpl(
  remoteDataSource: ref.watch(dailyUsageRemoteDataSourceProvider),
);

@riverpod
GetTodayUsage getTodayUsageUseCase(final Ref ref) =>
    GetTodayUsage(ref.watch(dailyUsageRepositoryProvider));

/// Today's usage row for the current user, and the single owner of usage-cache
/// writes. State is refreshed two ways:
/// 1. `build()` — read from server (cold start, day rollover, manual refresh).
/// 2. `syncFromSnapshot(...)` / `syncFromFailure(...)` — push the snapshot that
///    quota-consuming mutations (tryon, chat) inline in their responses, so the
///    cache updates without an extra round trip.
@riverpod
class DailyUsageToday extends _$DailyUsageToday {
  @override
  Future<DailyUsage> build() async {
    final useCase = ref.watch(getTodayUsageUseCaseProvider);
    final result = await useCase();
    if (result.isFailure) {
      throw result.getError()!;
    }
    return result.get()!;
  }

  void syncFromSnapshot(final DailyUsage? usage) {
    if (usage != null) {
      state = AsyncData(usage);
    }
  }

  void syncFromFailure(final Failure failure) {
    if (failure is RateLimitFailure && failure.usagePayload != null) {
      state = AsyncData(parseDailyUsagePayload(failure.usagePayload!));
    }
  }
}
