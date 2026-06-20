import 'package:tryzeon/feature/personal/chat/domain/entities/chat_message.dart';
import 'package:tryzeon/feature/personal/chat/domain/entities/chat_stream_event.dart';
import 'package:tryzeon/feature/personal/chat/domain/repositories/chat_repository.dart';

class SendChatMessageUseCase {
  SendChatMessageUseCase(this._repository);
  final ChatRepository _repository;

  Stream<ChatStreamEvent> call(final List<ChatMessage> history) {
    return _repository.sendMessageStream(history);
  }
}
