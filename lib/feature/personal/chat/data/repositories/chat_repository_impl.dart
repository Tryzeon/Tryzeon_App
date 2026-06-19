import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/utils/app_logger.dart';
import 'package:tryzeon/feature/personal/chat/data/datasources/chat_remote_data_source.dart';
import 'package:tryzeon/feature/personal/chat/domain/entities/chat_message.dart';
import 'package:tryzeon/feature/personal/chat/domain/entities/chat_reply.dart';
import 'package:tryzeon/feature/personal/chat/domain/entities/content_block.dart';
import 'package:tryzeon/feature/personal/chat/domain/repositories/chat_repository.dart';
import 'package:tryzeon/feature/personal/data/mappers/personal_mappr.dart';
import 'package:tryzeon/feature/personal/shop/data/models/product_row_mapper.dart';
import 'package:tryzeon/feature/personal/shop/data/models/shop_product_model.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_product.dart';
import 'package:tryzeon/feature/personal/usage/data/models/daily_usage_model.dart';
import 'package:tryzeon/feature/personal/wardrobe/data/models/wardrobe_item_model.dart';
import 'package:tryzeon/feature/personal/wardrobe/domain/entities/wardrobe_item.dart';
import 'package:typed_result/typed_result.dart';

class ChatRepositoryImpl implements ChatRepository {
  ChatRepositoryImpl({required final ChatRemoteDataSource remoteDataSource})
    : _remoteDataSource = remoteDataSource;
  final ChatRemoteDataSource _remoteDataSource;

  static const _mappr = PersonalMappr();

  @override
  Future<Result<ChatReply, Failure>> sendMessage(final List<ChatMessage> history) async {
    try {
      final data = await _remoteDataSource.sendMessage(history);

      final messages = _parseMessages(data['messages'] as List<dynamic>?);
      final usageJson = data['usage'] as Map<String, dynamic>?;

      return Ok(
        ChatReply(
          messages: messages,
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

  List<ChatMessage> _parseMessages(final List<dynamic>? raw) {
    final result = <ChatMessage>[];
    for (final m in raw ?? const []) {
      if (m is! Map<String, dynamic>) continue;
      final role = m['role'] == 'user' ? ChatRole.user : ChatRole.assistant;
      result.add(ChatMessage(role: role, content: _parseBlocks(m['content'] as List<dynamic>?)));
    }
    return result;
  }

  /// Each block is already a resolved real item or a raw tool trace, so we build
  /// the matching [ContentBlock] directly — no extra wardrobe/shop lookups.
  List<ContentBlock> _parseBlocks(final List<dynamic>? blocksJson) {
    final result = <ContentBlock>[];
    for (final raw in blocksJson ?? const []) {
      if (raw is! Map<String, dynamic>) continue;
      switch (raw['type'] as String?) {
        case 'text':
          final text = (raw['text'] as String? ?? '').trim();
          if (text.isEmpty) continue;
          result.add(ContentBlock.text(text));
        case 'tool_use':
          result.add(
            ContentBlock.toolUse(
              id: raw['id'] as String? ?? '',
              name: raw['name'] as String? ?? '',
              input: (raw['input'] as Map?)?.cast<String, dynamic>() ?? const {},
            ),
          );
        case 'tool_result':
          result.add(
            ContentBlock.toolResult(
              toolUseId: raw['tool_use_id'] as String? ?? '',
              content: (raw['content'] as Map?)?.cast<String, dynamic>() ?? const {},
            ),
          );
        case 'shop_product':
          final item = raw['item'];
          if (item is! Map<String, dynamic>) continue;
          result.add(
            ContentBlock.shopProduct(
              _mappr.convert<ShopProductModel, ShopProduct>(
                ShopProductModel.fromJson(productRowWithImageUrls(item)),
              ),
            ),
          );
        case 'wardrobe_product':
          final item = raw['item'];
          if (item is! Map<String, dynamic>) continue;
          result.add(
            ContentBlock.wardrobeProduct(
              _mappr.convert<WardrobeItemModel, WardrobeItem>(
                WardrobeItemModel.fromJson(item),
              ),
            ),
          );
      }
    }
    return result;
  }
}
