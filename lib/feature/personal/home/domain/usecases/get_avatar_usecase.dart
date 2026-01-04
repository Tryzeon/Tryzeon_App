import 'package:tryzeon/feature/personal/home/domain/entities/avatar.dart';
import 'package:tryzeon/feature/personal/home/domain/repositories/avatar_repository.dart';
import 'package:typed_result/typed_result.dart';

class GetAvatarUseCase {
  GetAvatarUseCase(this._repository);
  final AvatarRepository _repository;

  Future<Result<Avatar?, String>> call({final bool forceRefresh = false}) {
    return _repository.getAvatar(forceRefresh: forceRefresh);
  }
}
