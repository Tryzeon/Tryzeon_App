import 'package:flutter/material.dart';

import '../login/login_page.dart';

class SelfPage extends StatefulWidget {
  const SelfPage({super.key});

  @override
  State<SelfPage> createState() => _SelfPageState();
}

class _SelfPageState extends State<SelfPage> {
  String username = 'Ingrid';

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
        title: const Text('個人設定'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 使用者名稱區塊
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '您好, $username',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.grey),
                  onPressed: () {
                    _showEditUsernameDialog(context);
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 訂單狀態按鈕列
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _OrderStatusButton(
                  icon: Icons.payment,
                  label: '待付款',
                  onTap: () {
                    // TODO: 導向待付款頁面
                  },
                ),
                _OrderStatusButton(
                  icon: Icons.local_shipping,
                  label: '待出貨',
                  onTap: () {
                    // TODO: 導向待出貨頁面
                  },
                ),
                _OrderStatusButton(
                  icon: Icons.inventory_2,
                  label: '待收貨',
                  onTap: () {
                    // TODO: 導向待收貨頁面
                  },
                ),
              ],
            ),

            const SizedBox(height: 24),


            // 基本資料卡片
            Card(
              elevation: 2,
              color: const Color(0xFFF5EBDD),
              child: ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('基本資料'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.pushNamed(context, '/self_info');
                },
              ),
            ),
            const SizedBox(height: 12),

            // 帳號連結卡片
            Card(
              elevation: 2,
              color: const Color(0xFFF5EBDD),
              child: ListTile(
                leading: const Icon(Icons.link),
                title: const Text('帳號連結'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.pushNamed(context, '/self_link');
                },
              ),
            ),
            // 登出
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                icon: const Icon(Icons.logout, color: Colors.brown),
                label: const Text('登出', style: TextStyle(color: Colors.brown)),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        title: const Text('確認登出'),
                        content: const Text('您確定要登出嗎？'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('取消'),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.brown,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () {
                              Navigator.of(context).pop(); // 關閉 Dialog
                              _handleLogout(); // 執行登出跳轉
                            },
                            child: const Text('確認'),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),

          ],
        ),
      ),
    );
  }
  void _showEditUsernameDialog(BuildContext context) {
    final TextEditingController controller = TextEditingController(text: username);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('編輯使用者名稱'),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: '輸入新名稱',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                final newName = controller.text.trim();
                if (newName.isNotEmpty) {
                  setState(() {
                    username = newName;
                  });
                  Navigator.of(context).pop();
                }
              },
              child: const Text('儲存'),
            ),
          ],
        );
      },
    );
  }
}


class _OrderStatusButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _OrderStatusButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  //for 待收款 待付款 待出貨 icons
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            Icon(icon, size: 32, color: Colors.brown),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
