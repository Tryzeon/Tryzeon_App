import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_request.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_result.dart';
import 'package:tryzeon/feature/personal/tryon/domain/repositories/tryon_repository.dart';
import 'package:typed_result/typed_result.dart';

class Tryon {
  Tryon({required final TryonRepository tryonRepository})
    : _tryonRepository = tryonRepository;

  final TryonRepository _tryonRepository;

  Future<Result<TryonResult, Failure>> call(final TryonRequest request) {
    return _tryonRepository.tryon(request);
  }
}
