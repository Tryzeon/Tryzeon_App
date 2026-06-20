import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/utils/app_logger.dart';
import 'package:tryzeon/feature/personal/chat/data/datasources/chat_remote_data_source.dart';
import 'package:tryzeon/feature/personal/chat/domain/entities/chat_message.dart';
import 'package:tryzeon/feature/personal/chat/domain/entities/chat_stream_event.dart';
import 'package:tryzeon/feature/personal/chat/domain/repositories/chat_repository.dart';

class ChatRepositoryImpl implements ChatRepository {
  ChatRepositoryImpl({required final ChatRemoteDataSource remoteDataSource})
    : _remoteDataSource = remoteDataSource;
  final ChatRemoteDataSource _remoteDataSource;

  @override
  Stream<ChatStreamEvent> sendMessageStream(final List<ChatMessage> history) async* {
    try {
      await for (final event in _remoteDataSource.sendMessageStream(history)) {
        yield event;
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to stream chat message', e, stackTrace);
      yield ChatStreamEvent.failed(mapExceptionToFailure(e));
    }
  }
}
