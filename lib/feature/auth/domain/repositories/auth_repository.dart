import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/auth/domain/entities/login_provider.dart';
import 'package:tryzeon/feature/auth/domain/entities/user_type.dart';
import 'package:typed_result/typed_result.dart';

abstract class AuthRepository {
  Future<Result<void, Failure>> signInWithProvider({
    required final LoginProvider provider,
    required final UserType userType,
  });

  Future<Result<void, Failure>> signOut();

  Future<Result<UserType?, Failure>> getLastLoginType();

  Future<Result<void, Failure>> setLastLoginType(final UserType userType);

  Future<Result<void, Failure>> sendEmailOtp({
    required final String email,
    required final UserType userType,
  });

  Future<Result<void, Failure>> verifyEmailOtp({
    required final String email,
    required final String token,
    required final UserType userType,
  });

  Future<Result<void, Failure>> deleteAccount();
}
