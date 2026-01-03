import 'package:tryzeon/feature/auth/domain/repositories/auth_repository.dart';
import 'package:typed_result/typed_result.dart';

class SignOutUseCase {
  SignOutUseCase(this._repository);
  final AuthRepository _repository;

  Future<Result<void, String>> call() {
    return _repository.signOut();
  }
}
