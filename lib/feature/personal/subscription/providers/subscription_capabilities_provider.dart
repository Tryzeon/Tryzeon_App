import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/core/di/core_providers.dart';
import 'package:tryzeon/core/modules/revenue_cat/providers/revenue_cat_providers.dart';
import 'package:tryzeon/feature/personal/subscription/data/datasources/subscription_capabilities_local_datasource.dart';
import 'package:tryzeon/feature/personal/subscription/data/datasources/subscription_capabilities_remote_datasource.dart';
import 'package:tryzeon/feature/personal/subscription/data/repositories/subscription_capabilities_repository_impl.dart';
import 'package:tryzeon/feature/personal/subscription/domain/entities/subscription_capabilities.dart';
import 'package:tryzeon/feature/personal/subscription/domain/repositories/subscription_capabilities_repository.dart';
import 'package:tryzeon/feature/personal/subscription/domain/usecases/get_subscription_capabilities.dart';
import 'package:typed_result/typed_result.dart';

part 'subscription_capabilities_provider.g.dart';

@riverpod
SubscriptionCapabilitiesRemoteDataSource subscriptionCapabilitiesRemoteDataSource(
  final Ref ref,
) {
  return SubscriptionCapabilitiesRemoteDataSource(Supabase.instance.client);
}

@riverpod
SubscriptionCapabilitiesLocalDataSource subscriptionCapabilitiesLocalDataSource(
  final Ref ref,
) {
  return SubscriptionCapabilitiesLocalDataSource(
    ref.watch(isarServiceProvider),
    ref.watch(cacheEntryLocalDataSourceProvider),
  );
}

@riverpod
SubscriptionCapabilitiesRepository subscriptionCapabilitiesRepository(final Ref ref) {
  return SubscriptionCapabilitiesRepositoryImpl(
    remoteDataSource: ref.watch(subscriptionCapabilitiesRemoteDataSourceProvider),
    localDataSource: ref.watch(subscriptionCapabilitiesLocalDataSourceProvider),
  );
}

@riverpod
GetSubscriptionCapabilities getSubscriptionCapabilitiesUseCase(final Ref ref) {
  return GetSubscriptionCapabilities(
    ref.watch(subscriptionCapabilitiesRepositoryProvider),
  );
}

/// Capabilities of the tier the customer is on *right now*.
@Riverpod(keepAlive: true)
Future<SubscriptionCapabilities> subscriptionCapabilities(final Ref ref) async {
  final entitlement = await ref.watch(appSubscriptionEntitlementProvider.future);

  final useCase = ref.watch(getSubscriptionCapabilitiesUseCaseProvider);
  final result = await useCase(entitlement.tier);

  if (result.isFailure) {
    throw result.getError()!;
  }

  return result.get()!;
}
