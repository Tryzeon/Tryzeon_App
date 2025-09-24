import 'package:flutter/material.dart';

class SelfPageLink extends StatefulWidget {
  const SelfPageLink({super.key});

  @override
  State<SelfPageLink> createState() => _SelfPageLinkState();
}

class _SelfPageLinkState extends State<SelfPageLink> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedPayment;
  final List<String> _paymentOptions = [
    '信用卡',
    'Apple Pay',
    'LINE Pay',
    '街口支付',
    '超商付款',
  ];

  final TextEditingController _carrierController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('帳號連結設定'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Text('慣用支付方式', style: TextStyle(fontWeight: FontWeight.bold)),
              DropdownButtonFormField<String>(
                initialValue: _selectedPayment,
                items: _paymentOptions.map((method) {
                  return DropdownMenuItem(
                    value: method,
                    child: Text(method),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedPayment = value;
                  });
                },
                decoration: const InputDecoration(hintText: '請選擇支付方式'),
                validator: (value) => value == null ? '請選擇支付方式' : null,
              ),
              const SizedBox(height: 24),

              const Text('載具類型 / 編號', style: TextStyle(fontWeight: FontWeight.bold)),
              TextFormField(
                controller: _carrierController,
                decoration: const InputDecoration(hintText: '請輸入載具編號（如手機條碼）'),
                validator: (value) => value!.isEmpty ? '請填寫載具資訊' : null,
              ),
              const SizedBox(height: 24),

              const Text('寄收地址', style: TextStyle(fontWeight: FontWeight.bold)),
              TextFormField(
                controller: _addressController,
                maxLines: 3,
                decoration: const InputDecoration(hintText: '請輸入完整地址'),
                validator: (value) => value!.isEmpty ? '請填寫地址' : null,
              ),
              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    // TODO: 儲存資料或送出 API
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('帳號連結資料已儲存')),
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