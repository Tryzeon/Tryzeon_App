import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/personal/chat/domain/entities/chat_message.dart';
import 'package:tryzeon/feature/personal/chat/domain/entities/chat_reply.dart';
import 'package:tryzeon/feature/personal/chat/domain/repositories/chat_repository.dart';
import 'package:typed_result/typed_result.dart';

class SendChatMessageUseCase {
  SendChatMessageUseCase(this._repository);
  final ChatRepository _repository;

  Future<Result<ChatReply, Failure>> call(
    final List<ChatMessage> history, {
    final String? gender,
  }) {
    return _repository.sendMessage(history, gender: gender);
  }
}
