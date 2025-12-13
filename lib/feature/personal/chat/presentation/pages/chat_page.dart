import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:tryzeon/shared/dialogs/confirmation_dialog.dart';
import 'package:tryzeon/shared/widgets/top_notification.dart';
import 'package:typed_result/typed_result.dart';

import '../../data/chat_service.dart';

// Question data structure
class Question {
  const Question({required this.id, required this.text, required this.quickReplies});
  final String id;
  final String text;
  final List<String> quickReplies;
}

// ChatMessage model
class ChatMessage {
  ChatMessage({required this.text, required this.isUser, this.questionId});
  final String text;
  final bool isUser;
  final String? questionId;
}

// ChatBubble widget
class ChatBubble extends StatelessWidget {
  const ChatBubble({super.key, required this.message, this.child});
  final ChatMessage message;
  final Widget? child;

  @override
  Widget build(final BuildContext context) {
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
          gradient: isUser
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [colorScheme.primary, colorScheme.secondary],
                )
              : null,
          color: isUser ? null : colorScheme.surface,
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

// Q&A configuration
class QAConfig {
  static const List<Question> questions = [
    Question(id: 'when', text: '什麼時候要穿？', quickReplies: ['早上', '下午', '晚上', '週末', '上班日']),
    Question(id: 'where', text: '在哪穿？', quickReplies: ['辦公室', '咖啡廳', '戶外', '約會', '派對']),
    Question(id: 'who', text: '和誰？', quickReplies: ['自己', '朋友', '同事', '情人', '家人']),
    Question(id: 'what', text: '要做什麼？', quickReplies: ['工作', '休閒', '運動', '聚會', '拍照']),
    Question(
      id: 'how',
      text: '想要什麼風格？',
      quickReplies: ['簡約風', '時尚風', '復古風', '運動風', '混搭風'],
    ),
    Question(
      id: 'why',
      text: '為什麼想這樣穿？',
      quickReplies: ['嘗試新風格', '吸引目光', '舒適自在', '展現專業'],
    ),
  ];
}

// Quick reply button widget
class QuickReplyButton extends StatelessWidget {
  const QuickReplyButton({super.key, required this.text, required this.onTap});
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colorScheme.primary.withValues(alpha: 0.1),
              colorScheme.secondary.withValues(alpha: 0.1),
            ],
          ),
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
class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  List<ChatMessage> messages = [];
  TextEditingController controller = TextEditingController();
  final ScrollController scrollController = ScrollController();
  int currentQuestionIndex = 0;
  Map<String, String> answers = {};
  bool isWaitingForAnswer = true;
  bool isLoadingRecommendation = false;

  @override
  void initState() {
    super.initState();
    // Add greeting message first
    messages.add(ChatMessage(text: '你好，今天想怎麼穿呢？', isUser: false));
    // Start Q&A after a short delay
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        _askNextQuestion();
      }
    });
  }

  void _askNextQuestion() {
    if (currentQuestionIndex < QAConfig.questions.length) {
      final question = QAConfig.questions[currentQuestionIndex];
      setState(() {
        messages.add(
          ChatMessage(text: question.text, isUser: false, questionId: question.id),
        );
        isWaitingForAnswer = true;
      });
      scrollToBottom();
    } else {
      _showSummary();
    }
  }

  void _handleAnswer(final String answer, final String questionId) {
    if (!isWaitingForAnswer) return;

    setState(() {
      messages.add(ChatMessage(text: answer, isUser: true));
      answers[questionId] = answer;
      isWaitingForAnswer = false;
      currentQuestionIndex++;
    });
    scrollToBottom();

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _askNextQuestion();
      }
    });
  }

  void _showSummary() {
    setState(() {
      isWaitingForAnswer = false;
    });

    // Call LLM API directly without showing summary
    _getLLMRecommendation();
  }

  Future<void> _getLLMRecommendation() async {
    if (!mounted) return;

    setState(() {
      isLoadingRecommendation = true;
      messages.add(ChatMessage(text: '正在尋求穿搭大神...', isUser: false));
    });

    scrollToBottom();

    // 使用 ChatService 獲取 LLM 建議
    final result = await ChatService.getLLMRecommendation(answers);

    if (!mounted) return;

    // Remove loading message
    setState(() {
      messages.removeLast();
      isLoadingRecommendation = false;
    });

    if (result.isSuccess) {
      // Add LLM response
      setState(() {
        messages.add(ChatMessage(text: result.get()!, isUser: false));
      });
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

  void sendMessage(final String text) {
    if (text.trim().isEmpty || !isWaitingForAnswer) return;

    final currentQuestion = currentQuestionIndex < QAConfig.questions.length
        ? QAConfig.questions[currentQuestionIndex]
        : null;

    if (currentQuestion != null) {
      _handleAnswer(text, currentQuestion.id);
    }

    controller.clear();
  }

  Widget _buildQuickReplies() {
    if (!isWaitingForAnswer || currentQuestionIndex >= QAConfig.questions.length) {
      return const SizedBox.shrink();
    }

    final currentQuestion = QAConfig.questions[currentQuestionIndex];

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: currentQuestion.quickReplies
            .map(
              (final reply) => QuickReplyButton(
                text: reply,
                onTap: () => _handleAnswer(reply, currentQuestion.id),
              ),
            )
            .toList(),
      ),
    );
  }

  void scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted && scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _resetChat() {
    setState(() {
      messages.clear();
      currentQuestionIndex = 0;
      answers.clear();
      isWaitingForAnswer = true;
      isLoadingRecommendation = false;

      // Add greeting message
      messages.add(ChatMessage(text: '你好，今天想怎麼穿呢？', isUser: false));
    });

    // Start Q&A after a short delay
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        _askNextQuestion();
      }
    });
  }

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.surface,
              Color.alphaBlend(
                colorScheme.primary.withValues(alpha: 0.03),
                colorScheme.surface,
              ),
            ],
          ),
        ),
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
                        gradient: LinearGradient(
                          colors: [colorScheme.primary, colorScheme.secondary],
                        ),
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
                          _resetChat();
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
                  itemCount: messages.length,
                  itemBuilder: (final context, final index) {
                    return ChatBubble(message: messages[index]);
                  },
                ),
              ),

              // 快速回覆
              _buildQuickReplies(),

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
                              hintText: isWaitingForAnswer ? '請輸入您的回答...' : '',
                              hintStyle: textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurface.withValues(alpha: 0.5),
                              ),
                              enabled: !isLoadingRecommendation,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                            ),
                            onSubmitted: sendMessage,
                            enabled: !isLoadingRecommendation,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isLoadingRecommendation
                                ? [colorScheme.outlineVariant, colorScheme.outline]
                                : [colorScheme.primary, colorScheme.secondary],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: isLoadingRecommendation
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
              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }
}
