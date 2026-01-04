import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tryzeon/feature/personal/home/data/datasources/tryon_remote_data_source.dart';
import 'package:tryzeon/feature/personal/home/domain/entities/tryon_result.dart';
import 'package:tryzeon/feature/personal/home/domain/repositories/tryon_repository.dart';
import 'package:tryzeon/shared/utils/app_logger.dart';
import 'package:typed_result/typed_result.dart';

class TryOnRepositoryImpl implements TryOnRepository {
  TryOnRepositoryImpl({required final TryonRemoteDataSource tryonDataSource})
    : _tryonDataSource = tryonDataSource;

  final TryonRemoteDataSource _tryonDataSource;

  @override
  Future<Result<TryonResult, String>> tryon({
    final String? avatarBase64,
    final String? avatarPath,
    final String? clothesBase64,
    final String? clothesPath,
  }) async {
    try {
      final imageBase64 = await _tryonDataSource.tryon(
        avatarBase64: avatarBase64,
        avatarPath: avatarPath,
        clothesBase64: clothesBase64,
        clothesPath: clothesPath,
      );

      return Ok(TryonResult(imageBase64: imageBase64));
    } on FunctionException catch (e) {
      String message;
      switch (e.status) {
        case 403:
          message = '今日試穿次數已達上限，請明日再試或升級方案';
          break;
        case 422:
          message = 'AI 無法辨識圖片，請換一張試試';
          break;
        default:
          message = '虛擬試穿服務暫時無法使用，請稍後再試';
          AppLogger.error('虛擬試穿失敗 (FunctionException)', e);
          break;
      }
      return Err(message);
    } catch (e) {
      AppLogger.error('虛擬試穿失敗', e);
      return const Err('虛擬試穿服務暫時無法使用，請稍後再試');
    }
  }
}
