import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/personal/tryon/data/datasources/tryon_remote_data_source.dart';
import 'package:tryzeon/feature/personal/tryon/data/repositories/tryon_repository_impl.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_params.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_result.dart';
import 'package:tryzeon/feature/personal/tryon/domain/repositories/tryon_repository.dart';
import 'package:tryzeon/feature/personal/tryon/domain/usecases/tryon_usecase.dart';
import 'package:tryzeon/feature/personal/usage/data/models/daily_usage_model.dart';
import 'package:tryzeon/feature/personal/usage/presentation/providers/daily_usage_providers.dart';
import 'package:typed_result/typed_result.dart';

part 'tryon_providers.g.dart';

// Data Source Providers
@riverpod
TryonRemoteDataSource tryonRemoteDataSource(final Ref ref) {
  return TryonRemoteDataSource(Supabase.instance.client);
}

// Repository Providers
@riverpod
TryOnRepository tryOnRepository(final Ref ref) {
  final tryonDataSource = ref.watch(tryonRemoteDataSourceProvider);

  return TryOnRepositoryImpl(remoteDataSource: tryonDataSource);
}

// Use Case Providers
@riverpod
TryonUseCase tryonUseCase(final Ref ref) {
  final tryOnRepository = ref.watch(tryOnRepositoryProvider);
  return TryonUseCase(tryOnRepository: tryOnRepository);
}

/// Mutation orchestrator for try-on. Wraps [TryonUseCase] and additionally
/// pushes the post-mutation usage snapshot into [dailyUsageTodayProvider]'s
/// cache, so the Account card updates without a round trip.
///
/// UI should call this instead of [tryonUseCaseProvider] directly — that way
/// any new try-on entry point inherits the cache-sync side effect for free.
///
/// `keepAlive: true` because the orchestrator is invoked via `ref.read` (no
/// long-lived listener). Without it, autoDispose may tear the provider down
/// mid-await, causing "Cannot use Ref after dispose" when the async body
/// resumes.
@Riverpod(keepAlive: true)
class TryonAction extends _$TryonAction {
  @override
  void build() {}

  Future<Result<TryonResult, Failure>> execute(final TryOnParams params) async {
    final useCase = ref.read(tryonUseCaseProvider);
    final result = await useCase(params);

    if (result.isSuccess) {
      final usage = result.get()!.usage;
      if (usage != null) {
        ref.read(dailyUsageTodayProvider.notifier).updateFromResponse(usage);
      }
    } else {
      final failure = result.getError();
      if (failure is RateLimitFailure && failure.usagePayload != null) {
        final usage = DailyUsageModel.fromJson(failure.usagePayload!).toEntity();
        ref.read(dailyUsageTodayProvider.notifier).updateFromResponse(usage);
      }
    }

    return result;
  }
}
