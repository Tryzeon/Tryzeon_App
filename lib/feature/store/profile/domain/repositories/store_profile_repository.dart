import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/store/profile/domain/entities/store_profile.dart';
import 'package:typed_result/typed_result.dart';

abstract class StoreProfileRepository {
  Future<Result<StoreProfile?, Failure>> getStoreProfile({
    final bool forceRefresh = false,
  });

  Future<Result<void, Failure>> updateStoreProfile(final UpdateStoreProfileParams params);
}
