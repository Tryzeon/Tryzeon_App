import 'package:flutter/material.dart';

class QuestionDropdown extends StatefulWidget {
  final String title;
  final List<String> options;
  final Function(String) onAnswer;

  const QuestionDropdown({
    super.key,
    required this.title,
    required this.options,
    required this.onAnswer,
  });

  @override
  State<QuestionDropdown> createState() => _QuestionDropdownState();
}

class _QuestionDropdownState extends State<QuestionDropdown> {
  String? selected;
  TextEditingController customInput = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        DropdownButton<String>(
          hint: const Text("請選擇"),
          value: selected,
          items: [
            ...widget.options.map((opt) => DropdownMenuItem(value: opt, child: Text(opt))),
            const DropdownMenuItem(value: "其他", child: Text("其他")),
          ],
          onChanged: (value) {
            setState(() {
              selected = value;
              if (value != "其他") {
                widget.onAnswer(value!);
              }
            });
          },
        ),
        if (selected == "其他")
          TextField(
            controller: customInput,
            decoration: const InputDecoration(hintText: "請輸入自訂內容"),
            onSubmitted: (value) => widget.onAnswer(value),
          ),
      ],
    );
  }
}