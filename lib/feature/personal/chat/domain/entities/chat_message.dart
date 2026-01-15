import 'package:equatable/equatable.dart';

class ChatMessage extends Equatable {
  const ChatMessage({required this.text, required this.isUser, this.questionId});

  final String text;
  final bool isUser;
  final String? questionId;

  @override
  List<Object?> get props => [text, isUser, questionId];
}
