import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/presentation/dialogs/confirmation_dialog.dart';
import 'package:tryzeon/core/presentation/widgets/top_notification.dart';
import 'package:tryzeon/feature/personal/chat/domain/entities/chat_message.dart';
import 'package:tryzeon/feature/personal/chat/presentation/constants/qa_config.dart';
import 'package:tryzeon/feature/personal/chat/providers/chat_providers.dart';
import 'package:typed_result/typed_result.dart';

// ChatBubble widget
class ChatBubble extends HookConsumerWidget {
  const ChatBubble({super.key, required this.message, this.child});
  final ChatMessage message;
  final Widget? child;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final isUser = message.isUser;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isUser ? colorScheme.primary : colorScheme.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: isUser ? const Radius.circular(20) : const Radius.circular(4),
            bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            MarkdownBody(
              data: message.text,
              styleSheet: MarkdownStyleSheet(
                p: textTheme.bodyLarge?.copyWith(
                  color: isUser ? colorScheme.onPrimary : colorScheme.onSurface,
                  height: 1.4,
                ),
                strong: textTheme.bodyLarge?.copyWith(
                  color: isUser ? colorScheme.onPrimary : colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
                em: textTheme.bodyLarge?.copyWith(
                  color: isUser ? colorScheme.onPrimary : colorScheme.onSurface,
                  fontStyle: FontStyle.italic,
                ),
                h1: textTheme.headlineLarge?.copyWith(
                  color: isUser ? colorScheme.onPrimary : colorScheme.onSurface,
                ),
                h2: textTheme.headlineMedium?.copyWith(
                  color: isUser ? colorScheme.onPrimary : colorScheme.onSurface,
                  fontSize: 19,
                ),
                h3: textTheme.headlineSmall?.copyWith(
                  color: isUser ? colorScheme.onPrimary : colorScheme.onSurface,
                  fontSize: 17,
                ),
                listBullet: textTheme.bodyLarge?.copyWith(
                  color: isUser ? colorScheme.onPrimary : colorScheme.onSurface,
                ),
                code: textTheme.bodyLarge?.copyWith(
                  color: isUser ? colorScheme.onPrimary : colorScheme.onSurface,
                  backgroundColor: isUser
                      ? colorScheme.onPrimary.withValues(alpha: 0.2)
                      : colorScheme.surfaceContainerHighest,
                  fontFamily: 'monospace',
                ),
                codeblockDecoration: BoxDecoration(
                  color: isUser
                      ? colorScheme.onPrimary.withValues(alpha: 0.2)
                      : colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              shrinkWrap: true,
            ),
            if (child != null) child!,
          ],
        ),
      ),
    );
  }
}

// Quick reply button widget
class QuickReplyButton extends HookConsumerWidget {
  const QuickReplyButton({super.key, required this.text, required this.onTap});
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: colorScheme.primary.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Text(
                text,
                style: textTheme.labelLarge?.copyWith(color: colorScheme.primary),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ChatPage widget
class ChatPage extends HookConsumerWidget {
  const ChatPage({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final messages = useState<List<ChatMessage>>([]);
    final controller = useTextEditingController();
    final scrollController = useScrollController();
    final currentQuestionIndex = useState(0);
    final answers = useState<Map<String, String>>({});
    final isWaitingForAnswer = useState(true);
    final isLoadingRecommendation = useState(false);

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    void scrollToBottom() {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (context.mounted && scrollController.hasClients) {
          scrollController.animateTo(
            scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }

    Future<void> getLLMRecommendation() async {
      if (!context.mounted) return;

      isLoadingRecommendation.value = true;
      messages.value = [
        ...messages.value,
        const ChatMessage(text: '正在尋求穿搭大神...', isUser: false),
      ];

      scrollToBottom();

      // 使用 Use Case 獲取 LLM 建議
      final getLLMRecommendation = ref.read(getLLMRecommendationUseCaseProvider);
      final result = await getLLMRecommendation(answers.value);

      if (!context.mounted) return;

      // Remove loading message
      messages.value = List.from(messages.value)..removeLast();
      isLoadingRecommendation.value = false;

      if (result.isSuccess) {
        // Add LLM response
        messages.value = [
          ...messages.value,
          ChatMessage(text: result.get()!, isUser: false),
        ];
      } else {
        // Show error message
        TopNotification.show(
          context,
          message: result.getError()!,
          type: NotificationType.error,
        );
      }

      scrollToBottom();
    }

    void showSummary() {
      isWaitingForAnswer.value = false;

      // Call LLM API directly without showing summary
      getLLMRecommendation();
    }

    void askNextQuestion() {
      if (currentQuestionIndex.value < QAConfig.questions.length) {
        final question = QAConfig.questions[currentQuestionIndex.value];
        messages.value = [
          ...messages.value,
          ChatMessage(text: question.text, isUser: false, questionId: question.id),
        ];
        isWaitingForAnswer.value = true;
        scrollToBottom();
      } else {
        showSummary();
      }
    }

    void handleAnswer(final String answer, final String questionId) {
      if (!isWaitingForAnswer.value) return;

      messages.value = [...messages.value, ChatMessage(text: answer, isUser: true)];
      answers.value = {...answers.value, questionId: answer};
      isWaitingForAnswer.value = false;
      currentQuestionIndex.value++;
      scrollToBottom();

      Future.delayed(const Duration(milliseconds: 100), () {
        if (context.mounted) {
          askNextQuestion();
        }
      });
    }

    void sendMessage(final String text) {
      if (text.trim().isEmpty || !isWaitingForAnswer.value) return;

      final currentQuestion = currentQuestionIndex.value < QAConfig.questions.length
          ? QAConfig.questions[currentQuestionIndex.value]
          : null;

      if (currentQuestion != null) {
        handleAnswer(text, currentQuestion.id);
      }

      controller.clear();
    }

    void resetChat() {
      messages.value = [];
      currentQuestionIndex.value = 0;
      answers.value = {};
      isWaitingForAnswer.value = true;
      isLoadingRecommendation.value = false;

      // Add greeting message
      messages.value = [const ChatMessage(text: '你好，今天想怎麼穿呢？', isUser: false)];

      // Start Q&A after a short delay
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (context.mounted) {
          askNextQuestion();
        }
      });
    }

    useEffect(() {
      // Add greeting message first
      messages.value = [const ChatMessage(text: '你好，今天想怎麼穿呢？', isUser: false)];
      // Start Q&A after a short delay
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (context.mounted) {
          askNextQuestion();
        }
      });
      return null;
    }, []);

    Widget buildQuickReplies() {
      if (!isWaitingForAnswer.value ||
          currentQuestionIndex.value >= QAConfig.questions.length) {
        return const SizedBox.shrink();
      }

      final currentQuestion = QAConfig.questions[currentQuestionIndex.value];

      return Container(
        height: 60,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: currentQuestion.quickReplies
              .map(
                (final reply) => QuickReplyButton(
                  text: reply,
                  onTap: () => handleAnswer(reply, currentQuestion.id),
                ),
              )
              .toList(),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(color: colorScheme.surface),
        child: SafeArea(
          child: Column(
            children: [
              // 自訂 AppBar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.psychology_outlined,
                        color: colorScheme.onPrimary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('穿搭顧問', style: textTheme.headlineSmall),
                          Text(
                            'AI 時尚助手',
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.refresh_rounded, color: colorScheme.primary),
                      onPressed: () async {
                        final confirmed = await ConfirmationDialog.show(
                          context: context,
                          content: '你確定要重設整個對話嗎？',
                        );

                        if (confirmed == true) {
                          resetChat();
                        }
                      },
                    ),
                  ],
                ),
              ),

              // 訊息列表
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                  itemCount: messages.value.length,
                  itemBuilder: (final context, final index) {
                    return ChatBubble(message: messages.value[index]);
                  },
                ),
              ),

              // 快速回覆
              buildQuickReplies(),

              // 輸入框
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: TextField(
                            controller: controller,
                            decoration: InputDecoration(
                              hintText: isWaitingForAnswer.value ? '請輸入您的回答...' : '',
                              hintStyle: textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurface.withValues(alpha: 0.5),
                              ),
                              enabled: !isLoadingRecommendation.value,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                            ),
                            onSubmitted: sendMessage,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: isLoadingRecommendation.value
                              ? colorScheme.onSurface.withValues(alpha: 0.12)
                              : colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: isLoadingRecommendation.value
                                ? null
                                : () => sendMessage(controller.text),
                            borderRadius: BorderRadius.circular(24),
                            child: Icon(
                              Icons.send_rounded,
                              color: colorScheme.onPrimary,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 10 + (PlatformInfo.isIOS26OrHigher() ? 50 : 0)),
            ],
          ),
        ),
      ),
    );
  }
}
