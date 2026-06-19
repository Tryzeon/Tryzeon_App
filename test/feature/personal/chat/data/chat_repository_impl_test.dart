import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/feature/personal/chat/data/datasources/chat_remote_data_source.dart';
import 'package:tryzeon/feature/personal/chat/data/repositories/chat_repository_impl.dart';
import 'package:tryzeon/feature/personal/chat/domain/entities/chat_message.dart';
import 'package:tryzeon/feature/personal/chat/domain/entities/content_block.dart';
import 'package:typed_result/typed_result.dart';

class _FakeDataSource implements ChatRemoteDataSource {
  _FakeDataSource(this.response);
  final Map<String, dynamic> response;

  @override
  Future<Map<String, dynamic>> sendMessage(final List<ChatMessage> history) async =>
      response;
}

Map<String, dynamic> _shopRow() => {
  'id': 'p1',
  'store_id': 's1',
  'name': '白襯衫',
  'category_ids': ['c1'],
  'price': 590,
  'image_paths': ['s1/p1.jpg'],
  'created_at': '2026-06-19T00:00:00Z',
  'updated_at': '2026-06-19T00:00:00Z',
  'styles': <String>[],
  'seasons': <String>[],
  'product_variants': <dynamic>[],
  'store_profiles': {
    'id': 's1',
    'name': 'Acme',
    'address': '台北',
    'logo_path': null,
    'channels': <String>[],
  },
};

Map<String, dynamic> _wardrobeRow() => {
  'id': 'w1',
  'image_path': 'u1/bottoms/w1.jpg',
  'category': 'bottoms',
  'tags': ['深藍'],
  'created_at': '2026-06-19T00:00:00Z',
  'updated_at': '2026-06-19T00:00:00Z',
};

void main() {
  ChatRepositoryImpl repoWith(final Map<String, dynamic> response) =>
      ChatRepositoryImpl(remoteDataSource: _FakeDataSource(response));

  final history = [
    const ChatMessage(role: ChatRole.user, content: [ContentBlock.text('hi')]),
  ];

  test('parses a paired tool_use → tool_result → answer conversation', () async {
    final repo = repoWith({
      'messages': [
        {
          'role': 'assistant',
          'content': [
            {
              'type': 'tool_use',
              'id': 'tu_0',
              'name': 'search_products',
              'input': {'category_name': '裙裝', 'query': '冰雪奇緣裙'},
            },
          ],
        },
        {
          'role': 'user',
          'content': [
            {
              'type': 'tool_result',
              'tool_use_id': 'tu_0',
              'content': {
                'items': [_shopRow()],
              },
            },
          ],
        },
        {
          'role': 'assistant',
          'content': [
            {'type': 'text', 'text': '上身白襯衫'},
            {'type': 'shop_product', 'item': _shopRow()},
            {'type': 'wardrobe_product', 'item': _wardrobeRow()},
          ],
        },
      ],
    });

    final reply = (await repo.sendMessage(history)).get()!;
    expect(reply.messages, hasLength(3));

    final use = reply.messages[0].content.single as ToolUseBlock;
    expect(use.id, 'tu_0');
    expect(use.name, 'search_products');
    expect(use.input['query'], '冰雪奇緣裙');

    final toolResult = reply.messages[1].content.single as ToolResultBlock;
    expect(reply.messages[1].role, ChatRole.user);
    expect(toolResult.toolUseId, 'tu_0');
    expect(toolResult.content['items'] as List, hasLength(1));

    final answer = reply.messages[2];
    expect(answer.role, ChatRole.assistant);
    expect(answer.content[0], isA<TextBlock>());
    expect((answer.content[1] as ShopProductBlock).product.id, 'p1');
    expect((answer.content[2] as WardrobeProductBlock).item.id, 'w1');
  });

  test('parses a text-only answer turn', () async {
    final repo = repoWith({
      'messages': [
        {
          'role': 'assistant',
          'content': [
            {'type': 'text', 'text': '是白天還是晚上？'},
          ],
        },
      ],
    });
    final reply = (await repo.sendMessage(history)).get()!;
    expect(reply.messages.single.role, ChatRole.assistant);
    expect((reply.messages.single.content.single as TextBlock).text, '是白天還是晚上？');
  });

  test('empty messages yields no turns', () async {
    final repo = repoWith({'messages': <dynamic>[]});
    final reply = (await repo.sendMessage(history)).get()!;
    expect(reply.messages, isEmpty);
  });

  test('empty body yields no turns', () async {
    final repo = repoWith(<String, dynamic>{});
    final reply = (await repo.sendMessage(history)).get()!;
    expect(reply.messages, isEmpty);
  });
}
