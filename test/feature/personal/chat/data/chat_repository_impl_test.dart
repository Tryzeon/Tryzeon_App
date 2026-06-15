import 'package:flutter_test/flutter_test.dart';
import 'package:tryzeon/feature/personal/chat/data/datasources/chat_remote_data_source.dart';
import 'package:tryzeon/feature/personal/chat/data/repositories/chat_repository_impl.dart';
import 'package:tryzeon/feature/personal/chat/domain/entities/chat_message.dart';
import 'package:typed_result/typed_result.dart';

class _FakeDataSource implements ChatRemoteDataSource {
  _FakeDataSource(this.response);
  final Map<String, dynamic> response;

  @override
  Future<Map<String, dynamic>> sendMessage(
    final List<ChatMessage> history, {
    final String? gender,
  }) async => response;
}

void main() {
  ChatRepositoryImpl repoWith(final Map<String, dynamic> response) =>
      ChatRepositoryImpl(remoteDataSource: _FakeDataSource(response));

  const history = [ChatMessage(text: 'hi', isUser: true)];

  test('parses message-only reply', () async {
    final repo = repoWith({'message': '是白天還是晚上？'});
    final reply = (await repo.sendMessage(history)).get()!;
    expect(reply.message, '是白天還是晚上？');
    expect(reply.recommendation, isNull);
  });

  test('parses recommendation reply with slots', () async {
    final repo = repoWith({
      'message': '推薦這套',
      'recommendation': {
        'slots': [
          {
            'slot_label': '上衣',
            'category_name': '襯衫',
            'tags': ['白色'],
            'reason': '清爽',
          },
        ],
      },
    });
    final reply = (await repo.sendMessage(history)).get()!;
    expect(reply.message, '推薦這套');
    expect(reply.recommendation!.slots, hasLength(1));
    expect(reply.recommendation!.slots.first.categoryName, '襯衫');
  });

  test('drops slots with empty category_name', () async {
    final repo = repoWith({
      'recommendation': {
        'slots': [
          {'slot_label': '上衣', 'category_name': '', 'reason': 'x'},
        ],
      },
    });
    final reply = (await repo.sendMessage(history)).get()!;
    expect(reply.recommendation, isNull);
  });

  test('empty body yields reply with no message and no recommendation', () async {
    final repo = repoWith(<String, dynamic>{});
    final reply = (await repo.sendMessage(history)).get()!;
    expect(reply.message, isNull);
    expect(reply.recommendation, isNull);
  });
}
