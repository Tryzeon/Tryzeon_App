import 'dart:typed_data';

import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_result.dart';
import 'package:typed_result/typed_result.dart';

abstract class TryonMediaRepository {
  Future<Result<Uint8List, Failure>> loadImageBytes(final String url);

  Future<Result<void, Failure>> saveToGallery(final TryonResult result);

  Future<Result<void, Failure>> share(final TryonResult result);
}
