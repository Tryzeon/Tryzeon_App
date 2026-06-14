import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/personal/chat/domain/entities/chat_recommendation.dart';
import 'package:typed_result/typed_result.dart';

abstract class ChatRepository {
  Future<Result<ChatRecommendation, Failure>> getLLMRecommendation(
    final Map<String, String> answers, {
    final String? gender,
  });
}
