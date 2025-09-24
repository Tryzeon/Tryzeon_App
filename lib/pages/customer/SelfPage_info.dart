import 'package:flutter/material.dart';

class SelfPageInfo extends StatefulWidget {
  const SelfPageInfo({super.key});

  @override
  State<SelfPageInfo> createState() => _SelfPageInfoState();
}

class _SelfPageInfoState extends State<SelfPageInfo> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _bustController = TextEditingController();
  final TextEditingController _waistController = TextEditingController();
  final TextEditingController _hipController = TextEditingController();

  String? _selectedStyle;
  final List<String> _styleOptions = [
    '休閒',
    '街頭',
    '極簡',
    '甜美',
    '復古',
    '機能',
    '韓系',
    '歐美'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('基本資料設定'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Text('身高 (cm)', style: TextStyle(fontWeight: FontWeight.bold)),
              TextFormField(
                controller: _heightController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: '請輸入身高'),
                validator: (value) => value!.isEmpty ? '請填寫身高' : null,
              ),
              const SizedBox(height: 16),

              const Text('體重 (kg)', style: TextStyle(fontWeight: FontWeight.bold)),
              TextFormField(
                controller: _weightController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: '請輸入體重'),
                validator: (value) => value!.isEmpty ? '請填寫體重' : null,
              ),
              const SizedBox(height: 16),

              const Text('三圍 (cm)', style: TextStyle(fontWeight: FontWeight.bold)),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _bustController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(hintText: '胸圍'),
                      validator: (value) => value!.isEmpty ? '必填' : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _waistController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(hintText: '腰圍'),
                      validator: (value) => value!.isEmpty ? '必填' : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _hipController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(hintText: '臀圍'),
                      validator: (value) => value!.isEmpty ? '必填' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              const Text('偏好穿搭風格', style: TextStyle(fontWeight: FontWeight.bold)),
              DropdownButtonFormField<String>(
                value: _selectedStyle,
                items: _styleOptions.map((style) {
                  return DropdownMenuItem(
                    value: style,
                    child: Text(style),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedStyle = value;
                  });
                },
                decoration: const InputDecoration(hintText: '請選擇風格'),
                validator: (value) => value == null ? '請選擇風格' : null,
              ),
              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    // TODO: 儲存資料或送出 API
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('資料已儲存')),
                    );
                  }
                },
                child: const Text('儲存'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}