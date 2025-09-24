import 'package:flutter/material.dart';

import 'ChatHistorySidebar.dart';
import 'ChatMessage.dart';
import 'ChatSession.dart';
import 'ChatSinglePage.dart';

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
                  Navigator.of(context).pop(); // 關閉 Drawer
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