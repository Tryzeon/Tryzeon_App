import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/personal/chat/domain/entities/chat_message.dart';
import 'package:tryzeon/feature/personal/chat/domain/entities/chat_reply.dart';
import 'package:typed_result/typed_result.dart';

abstract class ChatRepository {
  /// Sends the full conversation [history] and returns the next LLM turn.
  Future<Result<ChatReply, Failure>> sendMessage(final List<ChatMessage> history);
}
