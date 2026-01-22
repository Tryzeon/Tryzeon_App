import 'package:tryzeon/feature/auth/domain/entities/user_type.dart';
import 'package:tryzeon/feature/auth/domain/repositories/auth_repository.dart';
import 'package:typed_result/typed_result.dart';

class VerifyEmailOtpUseCase {
  VerifyEmailOtpUseCase(this._repository);
  final AuthRepository _repository;

  Future<Result<void, String>> call({
    required final String email,
    required final String token,
    required final UserType userType,
  }) {
    return _repository.verifyEmailOtp(email: email, token: token, userType: userType);
  }
}
