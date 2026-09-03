import 'package:tryzeon/core/error/failures.dart';
import 'package:typed_result/typed_result.dart';

/// Repository for advertisement operations.
abstract class AdRepository {
  Future<Result<List<String>, Failure>> getAds({final bool forceRefresh = false});
}
