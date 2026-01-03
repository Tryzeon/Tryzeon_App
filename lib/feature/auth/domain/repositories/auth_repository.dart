import 'package:tryzeon/feature/auth/domain/entities/user_type.dart';
import 'package:typed_result/typed_result.dart';

abstract class AuthRepository {
  Future<Result<void, String>> signInWithProvider({
    required final String provider,
    required final UserType userType,
  });

  Future<Result<void, String>> signOut();

  Future<Result<UserType?, String>> getLastLoginType();

  Future<Result<void, String>> setLastLoginType(final UserType userType);
}
