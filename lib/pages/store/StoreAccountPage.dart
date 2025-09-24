import 'package:flutter/material.dart';

import '../Login/login_Page.dart';

class StoreAccountPage extends StatefulWidget {
  const StoreAccountPage({super.key});

  @override
  State<StoreAccountPage> createState() => _StoreAccountPageState();
}

class _StoreAccountPageState extends State<StoreAccountPage> {
  String address = '台南市東區中華東路一段123號';
  bool isEditing = false;
  final TextEditingController addressController = TextEditingController();

  void _toggleEdit() {
    setState(() {
      if (isEditing) {
        // 儲存編輯結果
        address = addressController.text.trim();
      } else {
        // 開始編輯，填入目前地址
        addressController.text = address;
      }
      isEditing = !isEditing;
    });
  }

  void _handleLogout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('帳號設定'),
        backgroundColor: Colors.grey[700],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: isEditing
                      ? TextField(
                    controller: addressController,
                    decoration: const InputDecoration(labelText: '商家地址'),
                  )
                      : Text(
                    '商家地址：$address',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
                IconButton(
                  icon: Icon(isEditing ? Icons.check : Icons.edit),
                  onPressed: _toggleEdit,
                ),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _handleLogout,
              icon: const Icon(Icons.logout),
              label: const Text('登出'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[700],
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}