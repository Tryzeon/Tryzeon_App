import 'dart:io';
import 'package:tryzeon/feature/store/profile/domain/entities/store_profile.dart';
import 'package:typed_result/typed_result.dart';

abstract class StoreProfileRepository {
  Future<StoreProfile?> getStoreProfile();

  Future<Result<void, String>> updateStoreProfile({
    required final StoreProfile original,
    required final StoreProfile target,
    final File? logoFile,
  });

  Future<Result<File, String>> getStoreLogo(final String path);
}
