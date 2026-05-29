import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/utils/app_logger.dart';
import 'package:tryzeon/feature/personal/tryon/data/datasources/tryon_remote_data_source.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_params.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_result.dart';
import 'package:tryzeon/feature/personal/tryon/domain/repositories/tryon_repository.dart';
import 'package:tryzeon/feature/personal/usage/data/models/daily_usage_model.dart';
import 'package:typed_result/typed_result.dart';

class TryOnRepositoryImpl implements TryOnRepository {
  TryOnRepositoryImpl({required final TryonRemoteDataSource remoteDataSource})
    : _remoteDataSource = remoteDataSource;

  final TryonRemoteDataSource _remoteDataSource;

  @override
  Future<Result<TryonResult, Failure>> tryon(final TryOnParams params) async {
    try {
      final data = await _remoteDataSource.tryon(params);
      final usageJson = data['usage'] as Map<String, dynamic>?;
      return Ok(
        TryonResult(
          id: params.requestId,
          imageUrl: data['imageUrl'] as String?,
          videoUrl: data['videoUrl'] as String?,
          mode: params.mode,
          usage: usageJson == null
              ? null
              : DailyUsageModel.fromJson(usageJson).toEntity(),
        ),
      );
    } catch (e, stackTrace) {
      AppLogger.error('Virtual try-on failed', e, stackTrace);
      return Err(mapExceptionToFailure(e));
    }
  }
}
