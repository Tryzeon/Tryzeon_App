import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/utils/app_logger.dart';
import 'package:tryzeon/feature/personal/chat/data/datasources/chat_remote_data_source.dart';
import 'package:tryzeon/feature/personal/chat/domain/entities/chat_message.dart';
import 'package:tryzeon/feature/personal/chat/domain/entities/chat_recommendation.dart';
import 'package:tryzeon/feature/personal/chat/domain/entities/chat_reply.dart';
import 'package:tryzeon/feature/personal/chat/domain/entities/outfit_slot.dart';
import 'package:tryzeon/feature/personal/chat/domain/repositories/chat_repository.dart';
import 'package:tryzeon/feature/personal/usage/data/models/daily_usage_model.dart';
import 'package:typed_result/typed_result.dart';

class ChatRepositoryImpl implements ChatRepository {
  ChatRepositoryImpl({required final ChatRemoteDataSource remoteDataSource})
    : _remoteDataSource = remoteDataSource;
  final ChatRemoteDataSource _remoteDataSource;

  @override
  Future<Result<ChatReply, Failure>> sendMessage(
    final List<ChatMessage> history, {
    final String? gender,
  }) async {
    try {
      final data = await _remoteDataSource.sendMessage(history, gender: gender);

      final message = (data['message'] as String?)?.trim();

      final recJson = data['recommendation'] as Map<String, dynamic>?;
      final slots = _parseSlots(recJson?['slots'] as List<dynamic>?);
      final recommendation = slots.isEmpty ? null : ChatRecommendation(slots: slots);

      final usageJson = data['usage'] as Map<String, dynamic>?;

      return Ok(
        ChatReply(
          message: (message?.isEmpty ?? true) ? null : message,
          recommendation: recommendation,
          usage: usageJson == null
              ? null
              : DailyUsageModel.fromJson(usageJson).toEntity(),
        ),
      );
    } catch (e, stackTrace) {
      AppLogger.error('Failed to send chat message', e, stackTrace);
      return Err(mapExceptionToFailure(e));
    }
  }

  List<OutfitSlot> _parseSlots(final List<dynamic>? slotsJson) {
    return (slotsJson ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(
          (final s) => OutfitSlot(
            slotLabel: s['slot_label'] as String? ?? '',
            categoryName: s['category_name'] as String? ?? '',
            tags: (s['tags'] as List<dynamic>? ?? const []).whereType<String>().toList(),
            reason: s['reason'] as String? ?? '',
          ),
        )
        .where((final s) => s.categoryName.isNotEmpty)
        .toList();
  }
}
