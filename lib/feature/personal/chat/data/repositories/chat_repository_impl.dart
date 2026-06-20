import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/utils/app_logger.dart';
import 'package:tryzeon/feature/personal/chat/data/datasources/chat_remote_data_source.dart';
import 'package:tryzeon/feature/personal/chat/domain/entities/chat_message.dart';
import 'package:tryzeon/feature/personal/chat/domain/entities/chat_reply.dart';
import 'package:tryzeon/feature/personal/chat/domain/repositories/chat_repository.dart';
import 'package:typed_result/typed_result.dart';

class ChatRepositoryImpl implements ChatRepository {
  ChatRepositoryImpl({required final ChatRemoteDataSource remoteDataSource})
    : _remoteDataSource = remoteDataSource;
  final ChatRemoteDataSource _remoteDataSource;

  @override
  Future<Result<ChatReply, Failure>> sendMessage(final List<ChatMessage> history) async {
    try {
      return Ok(await _remoteDataSource.sendMessage(history));
    } catch (e, stackTrace) {
      AppLogger.error('Failed to send chat message', e, stackTrace);
      return Err(mapExceptionToFailure(e));
    }
  }
}
