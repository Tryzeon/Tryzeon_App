import 'package:tryzeon/feature/auth/domain/entities/user_type.dart';
import 'package:tryzeon/feature/auth/domain/repositories/auth_repository.dart';
import 'package:typed_result/typed_result.dart';

class SetLastLoginTypeUseCase {
  SetLastLoginTypeUseCase(this._repository);
  final AuthRepository _repository;

  Future<Result<void, String>> call(final UserType userType) {
    return _repository.setLastLoginType(userType);
  }
}
