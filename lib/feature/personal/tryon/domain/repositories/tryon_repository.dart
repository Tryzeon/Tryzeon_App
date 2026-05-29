import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_params.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_result.dart';
import 'package:typed_result/typed_result.dart';

abstract class TryOnRepository {
  Future<Result<TryonResult, Failure>> tryon(final TryOnParams params);
}
