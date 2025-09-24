import 'ChatMessage.dart';

class ChatSession {
  //應該可以整個刪掉?屬於後端
  final String id;
  final String title;
  final List<ChatMessage> messages;

  ChatSession({required this.id, required this.title, required this.messages});
}