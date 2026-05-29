import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_params.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_result.dart';
import 'package:tryzeon/feature/personal/tryon/domain/repositories/tryon_repository.dart';
import 'package:typed_result/typed_result.dart';

class TryonUseCase {
  TryonUseCase({required final TryOnRepository tryOnRepository})
    : _tryOnRepository = tryOnRepository;

  final TryOnRepository _tryOnRepository;

  /// Performs virtual try-on.
  Future<Result<TryonResult, Failure>> call(final TryOnParams params) async {
    return _tryOnRepository.tryon(params);
  }
}
