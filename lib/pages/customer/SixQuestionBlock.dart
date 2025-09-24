import 'package:flutter/material.dart';

class SixWQuestionBlock extends StatefulWidget {
  final Function(String, String) onAnswer;
  final Function(String) onComplete;

  const SixWQuestionBlock({
    super.key,
    required this.onAnswer,
    required this.onComplete, // ← 加這行
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
      // ✅ 全部回答完成，組合訊息送出
      final summary = finalAnswers.entries
          .map((e) => "${e.key}：${e.value}")
          .join("\n");

      widget.onComplete(summary);
    } else {
      // ⚠️ 尚未完成，提示使用者補齊
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

            //確定button
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