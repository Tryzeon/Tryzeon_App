import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/utils/app_logger.dart';
import 'package:tryzeon/feature/personal/tryon/data/datasources/tryon_remote_data_source.dart';
import 'package:tryzeon/feature/personal/tryon/data/models/tryon_request_model.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_request.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_result.dart';
import 'package:tryzeon/feature/personal/tryon/domain/repositories/tryon_repository.dart';
import 'package:tryzeon/feature/personal/usage/usage.dart';
import 'package:typed_result/typed_result.dart';

class TryonRepositoryImpl implements TryonRepository {
  TryonRepositoryImpl({required final TryonRemoteDataSource remoteDataSource})
    : _remoteDataSource = remoteDataSource;

  final TryonRemoteDataSource _remoteDataSource;

  @override
  Future<Result<TryonResult, Failure>> tryon(final TryonRequest request) async {
    try {
      final response = await _remoteDataSource.tryon(
        TryonRequestModel.fromDomain(request),
      );
      final usageJson = response.usage;
      return Ok(
        TryonResult(
          id: request.requestId,
          imageUrl: response.imageUrl,
          videoUrl: response.videoUrl,
          mode: request.mode,
          usage: usageJson == null ? null : parseDailyUsagePayload(usageJson),
        ),
      );
    } catch (e, stackTrace) {
      AppLogger.error('Virtual try-on failed', e, stackTrace);
      return Err(mapExceptionToFailure(e));
    }
  }
}
