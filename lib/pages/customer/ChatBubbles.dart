import 'package:flutter/material.dart';
import 'package:tryzeon/pages/customer/ChatMessage.dart';

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