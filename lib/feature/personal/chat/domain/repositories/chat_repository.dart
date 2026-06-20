import 'package:tryzeon/feature/personal/chat/domain/entities/chat_message.dart';
import 'package:tryzeon/feature/personal/chat/domain/entities/chat_stream_event.dart';

abstract class ChatRepository {
  /// Streams the agent's progress and the final answer for [history].
  Stream<ChatStreamEvent> sendMessageStream(final List<ChatMessage> history);
}
