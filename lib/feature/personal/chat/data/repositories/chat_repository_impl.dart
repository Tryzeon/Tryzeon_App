import 'package:tryzeon/feature/personal/chat/data/datasources/chat_remote_data_source.dart';
import 'package:tryzeon/feature/personal/chat/domain/repositories/chat_repository.dart';
import 'package:tryzeon/shared/utils/app_logger.dart';
import 'package:typed_result/typed_result.dart';

class ChatRepositoryImpl implements ChatRepository {
  ChatRepositoryImpl({required final ChatRemoteDataSource remoteDataSource})
    : _remoteDataSource = remoteDataSource;
  final ChatRemoteDataSource _remoteDataSource;

  @override
  Future<Result<String, String>> getLLMRecommendation(
    final Map<String, String> answers,
  ) async {
    try {
      final recommendation = await _remoteDataSource.getLLMRecommendation(answers);
      return Ok(recommendation);
    } catch (e) {
      AppLogger.error('穿搭建議獲取失敗', e);
      return const Err('無法取得穿搭建議，請稍後再試');
    }
  }
}
