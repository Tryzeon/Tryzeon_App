import 'package:flutter/material.dart';

import 'ChatBubbles.dart';
import 'ChatMessage.dart';

import 'ChatSession.dart';
import 'SixQuestionBlock.dart';

class ChatSinglePage extends StatefulWidget {
  final ChatSession session;
  final Function(List<ChatMessage>) onUpdate;

  const ChatSinglePage({super.key, required this.session, required this.onUpdate});


  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatSinglePage> {
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
    //滾動到底部
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