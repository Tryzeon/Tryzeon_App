import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/auth/domain/entities/user_type.dart';
import 'package:tryzeon/feature/auth/domain/repositories/auth_repository.dart';
import 'package:typed_result/typed_result.dart';

class GetLastLoginType {
  GetLastLoginType(this._repository);
  final AuthRepository _repository;

  Future<Result<UserType?, Failure>> call() {
    return _repository.getLastLoginType();
  }
}
