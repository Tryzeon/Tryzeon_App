import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/auth/domain/entities/user_type.dart';
import 'package:tryzeon/feature/auth/domain/repositories/auth_repository.dart';
import 'package:typed_result/typed_result.dart';

class SendEmailOtp {
  SendEmailOtp(this._repository);
  final AuthRepository _repository;

  Future<Result<void, Failure>> call({
    required final String email,
    required final UserType userType,
  }) {
    return _repository.sendEmailOtp(email: email, userType: userType);
  }
}
