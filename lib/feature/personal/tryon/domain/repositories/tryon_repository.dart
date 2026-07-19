import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_request.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_result.dart';
import 'package:typed_result/typed_result.dart';

abstract class TryonRepository {
  Future<Result<TryonResult, Failure>> tryon(final TryonRequest request);
}
