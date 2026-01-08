import 'dart:io';
import 'package:tryzeon/feature/store/profile/domain/repositories/store_profile_repository.dart';
import 'package:typed_result/typed_result.dart';

class GetStoreLogo {
  GetStoreLogo(this._repository);
  final StoreProfileRepository _repository;

  Future<Result<File, String>> call(final String path) => 
      _repository.getStoreLogo(path);
}
