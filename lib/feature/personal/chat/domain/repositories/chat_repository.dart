import 'package:typed_result/typed_result.dart';

abstract class ChatRepository {
  Future<Result<String, String>> getLLMRecommendation(final Map<String, String> answers);
}
