import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/utils/app_logger.dart';
import 'package:tryzeon/feature/personal/chat/data/datasources/chat_remote_data_source.dart';
import 'package:tryzeon/feature/personal/chat/domain/entities/chat_recommendation.dart';
import 'package:tryzeon/feature/personal/chat/domain/entities/outfit_slot.dart';
import 'package:tryzeon/feature/personal/chat/domain/repositories/chat_repository.dart';
import 'package:tryzeon/feature/personal/usage/data/models/daily_usage_model.dart';
import 'package:typed_result/typed_result.dart';

class ChatRepositoryImpl implements ChatRepository {
  ChatRepositoryImpl({required final ChatRemoteDataSource remoteDataSource})
    : _remoteDataSource = remoteDataSource;
  final ChatRemoteDataSource _remoteDataSource;

  @override
  Future<Result<ChatRecommendation, Failure>> getLLMRecommendation(
    final Map<String, String> answers,
  ) async {
    try {
      final data = await _remoteDataSource.getLLMRecommendation(answers);
      final usageJson = data['usage'] as Map<String, dynamic>?;
      final slotsJson = data['slots'] as List<dynamic>? ?? const [];

      final slots = slotsJson
          .whereType<Map<String, dynamic>>()
          .map(
            (final s) => OutfitSlot(
              slotLabel: s['slot_label'] as String? ?? '',
              categoryName: s['category_name'] as String? ?? '',
              tags: (s['tags'] as List<dynamic>? ?? const [])
                  .whereType<String>()
                  .toList(),
              reason: s['reason'] as String? ?? '',
            ),
          )
          .where((final s) => s.categoryName.isNotEmpty)
          .toList();

      return Ok(
        ChatRecommendation(
          description: data['description'] as String? ?? '',
          slots: slots,
          usage: usageJson == null
              ? null
              : DailyUsageModel.fromJson(usageJson).toEntity(),
        ),
      );
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get outfit suggestions', e, stackTrace);
      return Err(mapExceptionToFailure(e));
    }
  }
}
