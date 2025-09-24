import 'package:flutter/material.dart';

// ChatMessage model
class ChatMessage {
  final String text;
  final bool isUser;

  ChatMessage({required this.text, required this.isUser});
}

// ChatSession model
class ChatSession {
  final String id;
  final String title;
  final List<ChatMessage> messages;

  ChatSession({required this.id, required this.title, required this.messages});
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
          children: [
            Text(
              message.text,
              style: TextStyle(
                color: isUser ? Colors.white : Colors.black87,
                fontSize: 16,
              ),
            ),
            if (child != null) child!,
          ],
        ),
      ),
    );
  }
}

// ChatHistorySidebar widget
class ChatHistorySidebar extends StatelessWidget {
  final List<ChatSession> sessions;
  final String selectedId;
  final Function(String) onSelect;

  const ChatHistorySidebar({
    super.key,
    required this.sessions,
    required this.selectedId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: sessions.map((session) {
        return ListTile(
          title: Text(session.title),
          onTap: () => onSelect(session.id),
        );
      }).toList(),
    );
  }
}

// QuestionDropdown widget
class QuestionDropdown extends StatefulWidget {
  final String title;
  final List<String> options;
  final Function(String) onAnswer;

  const QuestionDropdown({
    super.key,
    required this.title,
    required this.options,
    required this.onAnswer,
  });

  @override
  State<QuestionDropdown> createState() => _QuestionDropdownState();
}

class _QuestionDropdownState extends State<QuestionDropdown> {
  String? selected;
  TextEditingController customInput = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        DropdownButton<String>(
          hint: const Text("請選擇"),
          value: selected,
          items: [
            ...widget.options.map((opt) => DropdownMenuItem(value: opt, child: Text(opt))),
            const DropdownMenuItem(value: "其他", child: Text("其他")),
          ],
          onChanged: (value) {
            setState(() {
              selected = value;
              if (value != "其他") {
                widget.onAnswer(value!);
              }
            });
          },
        ),
        if (selected == "其他")
          TextField(
            controller: customInput,
            decoration: const InputDecoration(hintText: "請輸入自訂內容"),
            onSubmitted: (value) => widget.onAnswer(value),
          ),
      ],
    );
  }
}

// SixWQuestionBlock widget
class SixWQuestionBlock extends StatefulWidget {
  final Function(String, String) onAnswer;
  final Function(String) onComplete;

  const SixWQuestionBlock({
    super.key,
    required this.onAnswer,
    required this.onComplete,
  });

  @override
  State<SixWQuestionBlock> createState() => _SixWQuestionBlockState();
}

class _SixWQuestionBlockState extends State<SixWQuestionBlock> {
  final Map<String, List<String>> questions = {
    "🕒 When": ["早上", "下午", "晚上", "週末", "上班日"],
    "📍 Where": ["辦公室", "咖啡廳", "戶外", "約會", "派對"],
    "👥 Who": ["自己", "朋友", "同事", "情人", "家人"],
    "🎯 What": ["工作", "休閒", "運動", "聚會", "拍照"],
    "💡 Why": ["嘗試新風格", "吸引目光", "舒適自在", "展現專業"],
    "🧩 How": ["簡約風", "時尚風", "復古風", "運動風", "混搭風"],
  };

  final Map<String, String?> answers = {};
  final Map<String, TextEditingController> customInputs = {};

  @override
  void initState() {
    super.initState();
    for (var key in questions.keys) {
      customInputs[key] = TextEditingController();
    }
  }

  void handleConfirm() {
    final Map<String, String> finalAnswers = {};
    List<String> missing = [];

    for (var key in questions.keys) {
      final selected = answers[key];
      if (selected == null) {
        missing.add(key);
        continue;
      }

      if (selected == "其他") {
        final input = customInputs[key]?.text.trim();
        if (input == null || input.isEmpty) {
          missing.add(key);
        } else {
          finalAnswers[key] = input;
        }
      } else {
        finalAnswers[key] = selected;
      }
    }

    if (missing.isEmpty) {
      final summary = finalAnswers.entries
          .map((e) => "${e.key}：${e.value}")
          .join("\n");

      widget.onComplete(summary);
    } else {
      final missingText = missing.join("、");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("請完成以下項目：$missingText"),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: questions.entries.map((entry) {
        final title = entry.key;
        final options = entry.value;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            DropdownButton<String>(
              hint: const Text("請選擇"),
              value: answers[title],
              items: [
                ...options.map((opt) => DropdownMenuItem(value: opt, child: Text(opt))),
                const DropdownMenuItem(value: "其他", child: Text("其他")),
              ],
              onChanged: (value) {
                setState(() {
                  answers[title] = value;
                  if (value != "其他") {
                    widget.onAnswer(title, value!);
                  }
                });
              },
            ),
            if (answers[title] == "其他")
              TextField(
                controller: customInputs[title],
                decoration: const InputDecoration(hintText: "請輸入自訂內容"),
                onSubmitted: (value) {
                  widget.onAnswer(title, value);
                },
              ),
            const SizedBox(height: 12),
            if (title == "🧩 How")
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Center(
                  child: ElevatedButton(
                    onPressed: handleConfirm,
                    child: const Text("確定"),
                  ),
                ),
              ),
          ],
        );
      }).toList(),
    );
  }
}

// ChatSinglePage widget
class ChatSinglePage extends StatefulWidget {
  final ChatSession session;
  final Function(List<ChatMessage>) onUpdate;

  const ChatSinglePage({super.key, required this.session, required this.onUpdate});

  @override
  State<ChatSinglePage> createState() => _ChatSinglePageState();
}

class _ChatSinglePageState extends State<ChatSinglePage> {
  List<ChatMessage> messages = [];
  TextEditingController controller = TextEditingController();
  final ScrollController scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    messages.add(ChatMessage(text: "你好，今天想怎麼穿呢？", isUser: false));
  }

  void sendMessage(String text) {
    if (text.trim().isEmpty) return;

    setState(() {
      messages.add(ChatMessage(text: text, isUser: true));
    });
    scrollToBottom();

    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        messages.add(ChatMessage(text: "這是回覆：$text", isUser: false));
      });
      scrollToBottom();
    });
  }

  void handleSixWAnswer(String question, String answer) {
    setState(() {
      messages.add(ChatMessage(text: "$question：$answer", isUser: true));
    });
    scrollToBottom();

    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        messages.add(ChatMessage(text: "收到你的 $question：$answer，我來幫你搭配！", isUser: false));
      });
    });
  }

  void handleFormComplete(String summary) {
    setState(() {
      messages.add(ChatMessage(text: summary, isUser: true));
      messages.add(ChatMessage(text: "太好了，讓我們一起看看推薦穿搭吧！", isUser: false));
    });

    scrollToBottom();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Chat")),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                ChatBubble(
                  message: ChatMessage(text: "你好，今天想怎麼穿呢？", isUser: false),
                  child: SixWQuestionBlock(
                    onAnswer: (key, value) {
                      handleSixWAnswer(key, value);
                    },
                    onComplete: (summary) {
                      setState(() {
                        handleFormComplete(summary);
                      });
                    },
                  ),
                ),
                ...messages.map((msg) => ChatBubble(message: msg)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(child: TextField(controller: controller)),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () {
                    sendMessage(controller.text);
                    controller.clear();
                  },
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}

// Main ChatPage widget
class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  List<ChatSession> sessions = [
    ChatSession(id: "1", title: "秋季穿搭", messages: []),
    ChatSession(id: "2", title: "正式場合造型", messages: []),
  ];

  String selectedSessionId = "1";

  void updateSessionMessages(String sessionId, List<ChatMessage> updatedMessages) {
    setState(() {
      final index = sessions.indexWhere((s) => s.id == sessionId);
      if (index != -1) {
        sessions[index] = ChatSession(
          id: sessions[index].id,
          title: sessions[index].title,
          messages: updatedMessages,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectedSession = sessions.firstWhere((s) => s.id == selectedSessionId);

    return Scaffold(
      appBar: AppBar(
        title: Text(selectedSession.title),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: Drawer(
        child: Column(
          children: [
            AppBar(title: const Text("聊天紀錄"), automaticallyImplyLeading: false),
            Expanded(
              child: ChatHistorySidebar(
                sessions: sessions,
                selectedId: selectedSessionId,
                onSelect: (id) {
                  setState(() {
                    selectedSessionId = id;
                  });
                  Navigator.of(context).pop();
                },
              ),
            ),
          ],
        ),
      ),
      body: ChatSinglePage(
        session: selectedSession,
        onUpdate: (updatedMessages) {
          updateSessionMessages(selectedSessionId, updatedMessages);
        },
      ),
    );
  }
}