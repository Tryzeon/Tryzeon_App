import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/feature/personal/chat/domain/entities/chat_recommendation.dart';
import 'package:tryzeon/feature/personal/chat/domain/repositories/chat_repository.dart';
import 'package:typed_result/typed_result.dart';

class GetLLMRecommendationUseCase {
  GetLLMRecommendationUseCase(this._repository);
  final ChatRepository _repository;

  Future<Result<ChatRecommendation, Failure>> call(
    final Map<String, String> answers, {
    final String? gender,
  }) {
    return _repository.getLLMRecommendation(answers, gender: gender);
  }
}
