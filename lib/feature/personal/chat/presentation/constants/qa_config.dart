import 'package:tryzeon/feature/personal/chat/domain/entities/question.dart';

class QAConfig {
  static const List<Question> questions = [
    Question(id: 'when', text: '什麼時候要穿？', quickReplies: ['早上', '下午', '晚上', '週末', '上班日']),
    Question(id: 'where', text: '在哪穿？', quickReplies: ['辦公室', '咖啡廳', '戶外', '約會', '派對']),
    Question(id: 'who', text: '和誰？', quickReplies: ['自己', '朋友', '同事', '情人', '家人']),
    Question(id: 'what', text: '要做什麼？', quickReplies: ['工作', '休閒', '運動', '聚會', '拍照']),
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
