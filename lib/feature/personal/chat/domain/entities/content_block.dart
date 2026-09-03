import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tryzeon/feature/personal/shop/domain/entities/shop_product.dart';
import 'package:tryzeon/feature/personal/wardrobe/domain/entities/wardrobe_item.dart';

part 'content_block.freezed.dart';

/// One content block of a chat message — the standard chat-API shape (Anthropic
/// content blocks / OpenAI). A tool round spans messages: a [ToolUseBlock] in an
/// assistant message is paired (by [ToolUseBlock.id] ↔ [ToolResultBlock.toolUseId])
/// with a [ToolResultBlock] in the following user message.
@freezed
sealed class ContentBlock with _$ContentBlock {
  const factory ContentBlock.text(final String text) = TextBlock;

  const factory ContentBlock.toolUse({
    required final String id,
    required final String name,
    @Default(<String, dynamic>{}) final Map<String, dynamic> input,
  }) = ToolUseBlock;

  /// Not rendered; replayed as a function response so the model sees exactly
  /// what each search returned.
  const factory ContentBlock.toolResult({
    required final String toolUseId,
    @Default(<String, dynamic>{}) final Map<String, dynamic> content,
  }) = ToolResultBlock;

  const factory ContentBlock.shopProduct(final ShopProduct product) = ShopProductBlock;

  const factory ContentBlock.wardrobeProduct(final WardrobeItem item) =
      WardrobeProductBlock;
}
