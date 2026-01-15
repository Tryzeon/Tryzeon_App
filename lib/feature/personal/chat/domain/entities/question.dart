import 'package:equatable/equatable.dart';

class Question extends Equatable {
  const Question({required this.id, required this.text, required this.quickReplies});

  final String id;
  final String text;
  final List<String> quickReplies;

  @override
  List<Object?> get props => [id, text, quickReplies];
}
