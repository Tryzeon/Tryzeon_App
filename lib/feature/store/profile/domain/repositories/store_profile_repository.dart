import 'dart:io';
import 'package:tryzeon/feature/store/profile/domain/entities/store_profile.dart';
import 'package:typed_result/typed_result.dart';

abstract class StoreProfileRepository {
  Future<Result<StoreProfile?, String>> getStoreProfile();

  Future<Result<void, String>> updateStoreProfile({
    required final StoreProfile original,
    required final StoreProfile target,
    final File? logoFile,
  });
}
