import 'package:tryzeon/feature/store/profile/domain/entities/store_profile.dart';
import 'package:tryzeon/feature/store/profile/domain/repositories/store_profile_repository.dart';

class GetStoreProfile {
  GetStoreProfile(this._repository);
  final StoreProfileRepository _repository;

  Future<StoreProfile?> call() => _repository.getStoreProfile();
}
