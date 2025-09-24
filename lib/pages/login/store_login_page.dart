import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../store/StoreHomePage.dart';

class StoreLoginPage extends StatefulWidget {
  const StoreLoginPage({super.key});

  @override
  State<StoreLoginPage> createState() => _StoreLoginPageState();
}

class _StoreLoginPageState extends State<StoreLoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isLogin = true;
  
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleAuth() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    
    if (email.isEmpty || password.isEmpty) {
      _showError('請輸入帳號和密碼');
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final AuthResult result;
      
      if (_isLogin) {
        result = await AuthService.signIn(
          email: email,
          password: password,
          expectedUserType: UserType.store,
        );
        
        if (result.success && mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const StoreHomePage()),
          );
        } else if (!result.success) {
          _showError(result.errorMessage ?? '登入失敗');
        }
      } else {
        result = await AuthService.signUp(
          email: email,
          password: password,
          userType: UserType.store,
        );
        
        if (result.success && mounted) {
          _showSuccess('註冊成功！請確認您的電子郵件');
          setState(() {
            _isLogin = true;
          });
          _emailController.clear();
          _passwordController.clear();
        } else if (!result.success) {
          _showError(result.errorMessage ?? '註冊失敗');
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
  
  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isLogin ? '店家登入' : '店家註冊'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 40),
            Text(
              _isLogin ? '歡迎回來！' : '註冊新帳號',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '開始上架您的服飾商品',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: '電子郵件',
                hintText: '請輸入您的電子郵件',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: '密碼',
                hintText: '請輸入您的密碼',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            
            ElevatedButton(
              onPressed: _isLoading ? null : _handleAuth,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_isLogin ? '登入' : '註冊'),
            ),
            const SizedBox(height: 16),
            
            TextButton(
              onPressed: _isLoading
                  ? null
                  : () {
                      setState(() {
                        _isLogin = !_isLogin;
                      });
                    },
              child: Text(
                _isLogin ? '還沒有帳號？立即註冊' : '已有帳號？立即登入',
              ),
            ),
          ],
        ),
      ),
    );
  }
}