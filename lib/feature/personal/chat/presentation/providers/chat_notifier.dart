import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/extensions/failure_extension.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/personal/chat/domain/entities/chat_message.dart';
import 'package:tryzeon/feature/personal/chat/domain/entities/chat_recommendation.dart';
import 'package:tryzeon/feature/personal/chat/presentation/constants/qa_config.dart';
import 'package:tryzeon/feature/personal/chat/presentation/providers/chat_event.dart';
import 'package:tryzeon/feature/personal/chat/providers/chat_providers.dart';
import 'package:typed_result/typed_result.dart';

part 'chat_notifier.freezed.dart';
part 'chat_notifier.g.dart';

const String _greetingText = '你好，今天想怎麼穿呢？';
const String _rateLimitMessage = '今天的對話次數已達上限，升級方案就能繼續聊喔！';

@freezed
sealed class ChatState with _$ChatState {
  const factory ChatState({
    @Default([]) final List<ChatMessage> messages,
    @Default({}) final Map<String, String> answers,
    @Default(0) final int currentQuestionIndex,
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
    WidgetsBinding.instance.addPostFrameCallback((final _) => _initialize());
    return const ChatState();
  }

  void _initialize() {
    appendBotMessage(_greetingText);
    _appendNextQuestion(state.generation);
  }

  void reset() {
    state = ChatState(generation: state.generation + 1);
    WidgetsBinding.instance.addPostFrameCallback((final _) => _initialize());
  }

  void appendUserMessage(final String text) =>
      _appendMessage(ChatMessage(text: text, isUser: true));

  void appendBotMessage(final String text) =>
      _appendMessage(ChatMessage(text: text, isUser: false));

  void appendRecommendationMessage(final ChatRecommendation rec) => _appendMessage(
    ChatMessage(text: rec.description, isUser: false, recommendation: rec),
  );

  void _appendMessage(final ChatMessage message) {
    state = state.copyWith(messages: [...state.messages, message]);
  }

  Future<void> submitAnswer(final String answer) async {
    if (state.isLoading) return;
    final index = state.currentQuestionIndex;
    if (index >= QAConfig.questions.length) return;

    appendUserMessage(answer);

    final question = QAConfig.questions[index];
    final localGen = state.generation;
    state = state.copyWith(
      answers: {...state.answers, question.id: answer},
      currentQuestionIndex: index + 1,
      isLoading: true,
    );

    if (state.currentQuestionIndex < QAConfig.questions.length) {
      await _appendNextQuestion(localGen);
    } else {
      await _fetchRecommendation(localGen);
    }

    if (_isStale(localGen)) return;
    state = state.copyWith(isLoading: false);
  }

  bool _isStale(final int localGen) => localGen != state.generation;

  Future<void> _appendNextQuestion(final int localGen) async {
    final index = state.currentQuestionIndex;
    if (index >= QAConfig.questions.length) return;
    final question = QAConfig.questions[index];

    await Future<void>.delayed(AppDuration.slow);
    if (_isStale(localGen)) return;

    appendBotMessage(question.text);
  }

  Future<void> _fetchRecommendation(final int localGen) async {
    final result = await ref.read(chatActionProvider.notifier).execute(state.answers);

    if (_isStale(localGen)) return;

    if (result.isSuccess) {
      appendRecommendationMessage(result.get()!);
      return;
    }

    final failure = result.getError();
    if (failure is RateLimitFailure) {
      appendBotMessage(_rateLimitMessage);
      _events.add(const ChatEvent.rateLimited());
      return;
    }

    appendBotMessage(failure?.displayMessage() ?? '發生錯誤，請稍後再試');
  }
}
