import 'dart:async';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/extensions/failure_extension.dart';
import 'package:tryzeon/feature/personal/chat/domain/entities/chat_message.dart';
import 'package:tryzeon/feature/personal/chat/domain/entities/chat_stream_event.dart';
import 'package:tryzeon/feature/personal/chat/domain/entities/content_block.dart';
import 'package:tryzeon/feature/personal/chat/presentation/providers/chat_event.dart';
import 'package:tryzeon/feature/personal/chat/providers/chat_providers.dart';

part 'chat_notifier.freezed.dart';
part 'chat_notifier.g.dart';

const String _greetingText = '嗨！我是你的穿搭顧問 👗 告訴我你的需求吧 — 例如場合、風格，或想搭配的某件單品，我會幫你推薦合適的穿搭。';
const String _rateLimitMessage = '今天的對話次數已達上限，升級方案就能繼續聊喔！';
const String _emptyReplyMessage = '抱歉，我沒有理解，可以再說一次你的需求嗎？';
const String _errorMessage = '發生錯誤，請稍後再試';

const ChatMessage _greetingMessage = ChatMessage(
  role: ChatRole.assistant,
  content: [ContentBlock.text(_greetingText)],
);

ChatMessage _assistantText(final String text) =>
    ChatMessage(role: ChatRole.assistant, content: [ContentBlock.text(text)]);

ChatMessage _userText(final String text) =>
    ChatMessage(role: ChatRole.user, content: [ContentBlock.text(text)]);

@freezed
sealed class ChatState with _$ChatState {
  const factory ChatState({
    @Default([]) final List<ChatMessage> messages,
    @Default(false) final bool isLoading,
    @Default(0) final int generation,
  }) = _ChatState;
}

@riverpod
class ChatNotifier extends _$ChatNotifier {
  final StreamController<ChatEvent> _events = StreamController<ChatEvent>.broadcast();

  Stream<ChatEvent> get events => _events.stream;

  @override
  ChatState build() {
    ref.onDispose(_events.close);
    return const ChatState(messages: [_greetingMessage]);
  }

  void reset() {
    state = ChatState(
      messages: const [_greetingMessage],
      generation: state.generation + 1,
    );
  }

  void _append(final ChatMessage message) {
    state = state.copyWith(messages: [...state.messages, message]);
  }

  bool _isStale(final int localGen) => localGen != state.generation;

  Future<void> sendMessage(final String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || state.isLoading) return;

    _append(_userText(trimmed));
    final localGen = state.generation;

    // remove first greeting message
    final history = state.messages.skip(1).toList();
    state = state.copyWith(isLoading: true);

    final stream = ref.read(chatActionProvider.notifier).execute(history);
    var terminated = false;
    await for (final event in stream) {
      if (_isStale(localGen)) return; // reset() mid-stream cancels the subscription
      switch (event) {
        case ChatToolStarted(:final block):
          _append(ChatMessage(role: ChatRole.assistant, content: [block]));
        case ChatToolFinished(:final block):
          _append(ChatMessage(role: ChatRole.user, content: [block]));
        case ChatReplied(:final answer):
          terminated = true;
          if (answer.content.isEmpty) {
            _append(_assistantText(_emptyReplyMessage));
          } else {
            _append(answer);
          }
        case ChatFailed(:final failure):
          terminated = true;
          _applyFailure(failure);
      }
    }

    if (_isStale(localGen)) return;
    if (!terminated) {
      // Stream ended without a terminal answer or failure (e.g. dropped connection).
      _append(_assistantText(_errorMessage));
    }
    state = state.copyWith(isLoading: false);
  }

  void _applyFailure(final Failure failure) {
    if (failure is RateLimitFailure) {
      _append(_assistantText(_rateLimitMessage));
      _events.add(const ChatEvent.rateLimited());
      return;
    }
    _append(_assistantText(failure.displayMessage()));
  }
}
