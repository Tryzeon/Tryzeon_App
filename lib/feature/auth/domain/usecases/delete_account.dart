import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/auth/domain/repositories/auth_repository.dart';
import 'package:typed_result/typed_result.dart';

class DeleteAccount {
  DeleteAccount(this._repository);
  final AuthRepository _repository;

  Future<Result<void, Failure>> call() {
    return _repository.deleteAccount();
  }
}
