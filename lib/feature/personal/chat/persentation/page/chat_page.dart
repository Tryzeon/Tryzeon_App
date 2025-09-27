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
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUser ? Colors.blueAccent : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
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
                  fontSize: 16,
                ),
                strong: TextStyle(
                  color: isUser ? Colors.white : Colors.black87,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                em: TextStyle(
                  color: isUser ? Colors.white : Colors.black87,
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                ),
                h1: TextStyle(
                  color: isUser ? Colors.white : Colors.black87,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                h2: TextStyle(
                  color: isUser ? Colors.white : Colors.black87,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                h3: TextStyle(
                  color: isUser ? Colors.white : Colors.black87,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                listBullet: TextStyle(
                  color: isUser ? Colors.white : Colors.black87,
                  fontSize: 16,
                ),
                code: TextStyle(
                  color: isUser ? Colors.white : Colors.black87,
                  backgroundColor: isUser ? Colors.blue.shade700 : Colors.grey.shade300,
                  fontFamily: 'monospace',
                ),
                codeblockDecoration: BoxDecoration(
                  color: isUser ? Colors.blue.shade700 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
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
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: Text(text),
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
      height: 50,
      padding: const EdgeInsets.symmetric(vertical: 8),
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
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text(
          '穿搭顧問',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('重設對話'),
                    content: const Text('確定要重設整個對話嗎？'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('取消'),
                      ),
                      ElevatedButton(
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
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.all(12),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  return ChatBubble(message: messages[index]);
                },
              ),
            ),
          _buildQuickReplies(),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      hintText: isWaitingForAnswer ? '請輸入您的回答...' : '',
                      enabled: !isLoadingRecommendation,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: (text) => sendMessage(text),
                    enabled: !isLoadingRecommendation,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: isLoadingRecommendation ? null : () => sendMessage(controller.text),
                )
              ],
            ),
          )
          ],
        ),
      ),
    );
  }
}

