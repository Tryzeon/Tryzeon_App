import 'package:flutter/material.dart';
import 'customer/HomeNavigator.dart';
import 'package:tryzeon/pages/store/StoreHomePage.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final List<bool> isSelected = [true, false]; // [個人, 店家]

  void _handleLogin(BuildContext context) {
    // TODO: 加入帳號密碼驗證邏輯

    if (isSelected[0]) {
      // 個人登入
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeNavigator()),
      );
    } else {
      // 店家登入
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const StoreHomePage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 80),
            Text("歡迎登入 TryZeon", style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 40),

            // 帳號欄位
            TextField(
              decoration: InputDecoration(labelText: "帳號"),
            ),

            // 密碼欄位
            TextField(
              obscureText: true,
              decoration: InputDecoration(labelText: "密碼"),
            ),

            // 記住帳號密碼 + 登入類型選擇
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Checkbox(value: true, onChanged: (_) {}),
                    const Text("記住帳號密碼"),
                  ],
                ),
                ToggleButtons(
                  isSelected: isSelected,
                  onPressed: (index) {
                    setState(() {
                      for (int i = 0; i < isSelected.length; i++) {
                        isSelected[i] = i == index;
                      }
                    });
                  },
                  children: const [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text("個人登入"),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text("店家登入"),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 30),

            // 登入與註冊按鈕
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => _handleLogin(context),
                  child: const Text("登入"),
                ),
                OutlinedButton(onPressed: () {}, child: const Text("註冊")),
              ],
            ),
          ],
        ),
      ),
    );
  }
}