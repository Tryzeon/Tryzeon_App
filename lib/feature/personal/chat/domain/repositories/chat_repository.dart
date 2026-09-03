import 'package:tryzeon/feature/personal/chat/domain/entities/chat_message.dart';
import 'package:tryzeon/feature/personal/chat/domain/entities/chat_stream_event.dart';

abstract class ChatRepository {
  Stream<ChatStreamEvent> sendMessageStream(final List<ChatMessage> history);
}
