import 'package:tryzeon/feature/auth/domain/entities/user_type.dart';
import 'package:tryzeon/feature/auth/domain/repositories/auth_repository.dart';
import 'package:typed_result/typed_result.dart';

class SignInWithProviderUseCase {
  SignInWithProviderUseCase(this._repository);
  final AuthRepository _repository;

  Future<Result<void, String>> call({
    required final String provider,
    required final UserType userType,
  }) {
    return _repository.signInWithProvider(provider: provider, userType: userType);
  }
}
