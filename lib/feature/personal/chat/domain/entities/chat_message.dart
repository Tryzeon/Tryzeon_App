class ChatMessage {
  ChatMessage({required this.text, required this.isUser, this.questionId});

  final String text;
  final bool isUser;
  final String? questionId;
}
