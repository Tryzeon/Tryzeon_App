import 'dart:async';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/extensions/failure_extension.dart';
import 'package:tryzeon/feature/personal/chat/domain/entities/chat_message.dart';
import 'package:tryzeon/feature/personal/chat/domain/entities/chat_reply.dart';
import 'package:tryzeon/feature/personal/chat/presentation/providers/chat_event.dart';
import 'package:tryzeon/feature/personal/chat/providers/chat_providers.dart';
import 'package:typed_result/typed_result.dart';

part 'chat_notifier.freezed.dart';
part 'chat_notifier.g.dart';

const String _greetingText = '嗨！我是你的穿搭顧問 👗 告訴我你的需求吧 — 例如場合、風格，或想搭配的某件單品，我會幫你推薦合適的穿搭。';
const String _rateLimitMessage = '今天的對話次數已達上限，升級方案就能繼續聊喔！';
const String _emptyReplyMessage = '抱歉，我沒有理解，可以再說一次你的需求嗎？';
const String _errorMessage = '發生錯誤，請稍後再試';

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
    return const ChatState(messages: [ChatMessage(text: _greetingText, isUser: false)]);
  }

  void reset() {
    state = ChatState(
      messages: const [ChatMessage(text: _greetingText, isUser: false)],
      generation: state.generation + 1,
    );
    ref.invalidate(resolvedOutfitProvider);
  }

  void _append(final ChatMessage message) {
    state = state.copyWith(messages: [...state.messages, message]);
  }

  bool _isStale(final int localGen) => localGen != state.generation;

  Future<void> sendMessage(final String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || state.isLoading) return;

    _append(ChatMessage(text: trimmed, isUser: true));

    final localGen = state.generation;
    final history = state.messages
        .where((final m) => !(m.text == _greetingText && !m.isUser))
        .toList();
    state = state.copyWith(isLoading: true);

    final result = await ref.read(chatActionProvider.notifier).execute(history);

    if (_isStale(localGen)) return;

    _applyResult(result);
    state = state.copyWith(isLoading: false);
  }

  void _applyResult(final Result<ChatReply, Failure> result) {
    if (result.isSuccess) {
      final reply = result.get()!;
      final message = reply.message;
      final recommendation = reply.recommendation;

      if (message != null && message.isNotEmpty) {
        _append(ChatMessage(text: message, isUser: false));
      }
      if (recommendation != null && recommendation.slots.isNotEmpty) {
        _append(ChatMessage(text: '', isUser: false, recommendation: recommendation));
      }
      if ((message == null || message.isEmpty) && recommendation == null) {
        _append(const ChatMessage(text: _emptyReplyMessage, isUser: false));
      }
      return;
    }

    final failure = result.getError();
    if (failure is RateLimitFailure) {
      _append(const ChatMessage(text: _rateLimitMessage, isUser: false));
      _events.add(const ChatEvent.rateLimited());
      return;
    }

    _append(ChatMessage(text: failure?.displayMessage() ?? _errorMessage, isUser: false));
  }
}
