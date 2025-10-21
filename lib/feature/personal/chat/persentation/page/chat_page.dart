import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../data/chat_service.dart';

// Question data structure
class Question {
  final String id;
  final String text;
  final List<String> quickReplies;

  const Question({
    required this.id,
    required this.text,
    required this.quickReplies,
  });
}

// ChatMessage model
class ChatMessage {
  final String text;
  final bool isUser;
  final String? questionId;

  ChatMessage({
    required this.text,
    required this.isUser,
    this.questionId,
  });
}


// ChatBubble widget
class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final Widget? child;

  const ChatBubble({super.key, required this.message, this.child});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: isUser
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.secondary,
                  ],
                )
              : null,
          color: isUser ? null : Colors.white,
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
                p: TextStyle(
                  color: isUser ? Colors.white : Colors.black87,
                  fontSize: 15,
                  height: 1.4,
                ),
                strong: TextStyle(
                  color: isUser ? Colors.white : Colors.black87,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
                em: TextStyle(
                  color: isUser ? Colors.white : Colors.black87,
                  fontSize: 15,
                  fontStyle: FontStyle.italic,
                ),
                h1: TextStyle(
                  color: isUser ? Colors.white : Colors.black87,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                h2: TextStyle(
                  color: isUser ? Colors.white : Colors.black87,
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
                h3: TextStyle(
                  color: isUser ? Colors.white : Colors.black87,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
                listBullet: TextStyle(
                  color: isUser ? Colors.white : Colors.black87,
                  fontSize: 15,
                ),
                code: TextStyle(
                  color: isUser ? Colors.white : Colors.black87,
                  backgroundColor: isUser
                      ? Colors.white.withValues(alpha: 0.2)
                      : Colors.grey.shade200,
                  fontFamily: 'monospace',
                ),
                codeblockDecoration: BoxDecoration(
                  color: isUser
                      ? Colors.white.withValues(alpha: 0.2)
                      : Colors.grey.shade200,
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
    Question(
      id: 'when',
      text: '什麼時候要穿？',
      quickReplies: ['早上', '下午', '晚上', '週末', '上班日'],
    ),
    Question(
      id: 'where',
      text: '在哪穿？',
      quickReplies: ['辦公室', '咖啡廳', '戶外', '約會', '派對'],
    ),
    Question(
      id: 'who',
      text: '和誰？',
      quickReplies: ['自己', '朋友', '同事', '情人', '家人'],
    ),
    Question(
      id: 'what',
      text: '要做什麼？',
      quickReplies: ['工作', '休閒', '運動', '聚會', '拍照'],
    ),
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
  final String text;
  final VoidCallback onTap;

  const QuickReplyButton({
    super.key,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
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
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
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
    messages.add(ChatMessage(
      text: '你好，今天想怎麼穿呢？',
      isUser: false,
    ));
    // Start Q&A after a short delay
    Future.delayed(const Duration(milliseconds: 1000), () {
      _askNextQuestion();
    });
  }

  void _askNextQuestion() {
    if (currentQuestionIndex < QAConfig.questions.length) {
      final question = QAConfig.questions[currentQuestionIndex];
      setState(() {
        messages.add(ChatMessage(
          text: question.text,
          isUser: false,
          questionId: question.id,
        ));
        isWaitingForAnswer = true;
      });
      scrollToBottom();
    } else {
      _showSummary();
    }
  }

  void _handleAnswer(String answer, String questionId) {
    if (!isWaitingForAnswer) return;

    setState(() {
      messages.add(ChatMessage(text: answer, isUser: true));
      answers[questionId] = answer;
      isWaitingForAnswer = false;
      currentQuestionIndex++;
    });
    scrollToBottom();

    Future.delayed(const Duration(milliseconds: 100), () {
      _askNextQuestion();
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
    setState(() {
      isLoadingRecommendation = true;
      messages.add(ChatMessage(
        text: '正在尋求穿搭大神...',
        isUser: false,
      ));
    });
    scrollToBottom();
    
    try {
      // 使用 ChatService 獲取 LLM 建議
      final recommendationText = await ChatService.getLLMRecommendation(answers);
      
      // Remove loading message
      setState(() {
        messages.removeLast();
        isLoadingRecommendation = false;
      });
      
      // Add LLM response
      setState(() {
        messages.add(ChatMessage(
          text: recommendationText,
          isUser: false,
        ));
      });
      
    } catch (e) {
      // Remove loading message and show error
      setState(() {
        messages.removeLast();
        isLoadingRecommendation = false;
        messages.add(ChatMessage(
          text: '抱歉，發生錯誤：${e.toString()}',
          isUser: false,
        ));
      });
    }
    
    scrollToBottom();
  }

  void sendMessage(String text) {
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
            .map((reply) => QuickReplyButton(
                  text: reply,
                  onTap: () => _handleAnswer(reply, currentQuestion.id),
                ))
            .toList(),
      ),
    );
  }

  void scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
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
      messages.add(ChatMessage(
        text: '你好，今天想怎麼穿呢？',
        isUser: false,
      ));
    });
    
    // Start Q&A after a short delay
    Future.delayed(const Duration(milliseconds: 1000), () {
      _askNextQuestion();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.surface,
              Color.alphaBlend(
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.03),
                Theme.of(context).colorScheme.surface,
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
                  color: Colors.white,
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
                          colors: [
                            Theme.of(context).colorScheme.primary,
                            Theme.of(context).colorScheme.secondary,
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.psychology_outlined,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '穿搭顧問',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'AI 時尚助手',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.refresh_rounded,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              title: const Text(
                                '重設對話',
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              content: const Text(
                                '確定要重設整個對話嗎？',
                                style: TextStyle(
                                  color: Colors.black87,
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: Text(
                                    '取消',
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Theme.of(context).colorScheme.primary,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                    _resetChat();
                                  },
                                  child: const Text('確定'),
                                ),
                              ],
                            );
                          },
                        );
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
                  itemBuilder: (context, index) {
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
                    color: Colors.white,
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
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: TextField(
                            controller: controller,
                            decoration: InputDecoration(
                              hintText: isWaitingForAnswer ? '請輸入您的回答...' : '',
                              hintStyle: TextStyle(color: Colors.grey[500]),
                              enabled: !isLoadingRecommendation,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                            ),
                            onSubmitted: (text) => sendMessage(text),
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
                                ? [Colors.grey[300]!, Colors.grey[400]!]
                                : [
                                    Theme.of(context).colorScheme.primary,
                                    Theme.of(context).colorScheme.secondary,
                                  ],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: isLoadingRecommendation ? null : () => sendMessage(controller.text),
                            borderRadius: BorderRadius.circular(24),
                            child: const Icon(
                              Icons.send_rounded,
                              color: Colors.white,
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

