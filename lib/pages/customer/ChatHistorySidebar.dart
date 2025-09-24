import 'package:flutter/material.dart';
import 'ChatSession.dart';

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