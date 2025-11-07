import 'package:flutter/material.dart';
import 'package:tryzeon/shared/services/account_service.dart';
import 'package:tryzeon/shared/widgets/top_notification.dart';

class ProfileEditPage extends StatefulWidget {
  const ProfileEditPage({super.key});

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final displayName = AccountService.displayName;
    setState(() {
      _nameController.text = displayName;
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final result = await AccountService.updateUserName(_nameController.text);

    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      if (result.success) {
        Navigator.pop(context, true);
        TopNotification.show(
          context,
          message: '個人資料已更新',
          type: NotificationType.success,
        );
      } else {
        TopNotification.show(
          context,
          message: result.errorMessage ?? '更新失敗',
          type: NotificationType.error,
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.surface,
              Color.alphaBlend(
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
                Theme.of(context).colorScheme.surface,
              ),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 自訂 AppBar
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.arrow_back_ios_rounded,
                          color: Theme.of(context).colorScheme.primary,
                          size: 20,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '編輯個人資料',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '更新您的個人資訊',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 表單內容
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),

                        // 表單卡片
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 圖示標題
                              Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                                          Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.person_outline_rounded,
                                      color: Theme.of(context).colorScheme.primary,
                                      size: 28,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    '基本資料',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),

                              // 姓名欄位
                              TextFormField(
                                controller: _nameController,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                                decoration: InputDecoration(
                                  labelText: '姓名',
                                  labelStyle: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.person_outline_rounded,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.grey[300]!),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.grey[300]!),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Theme.of(context).colorScheme.primary,
                                      width: 2,
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return '請輸入姓名';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        // 儲存按鈕
                        Container(
                          width: double.infinity,
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: _isLoading
                                ? LinearGradient(
                                    colors: [Colors.grey[300]!, Colors.grey[400]!],
                                  )
                                : LinearGradient(
                                    colors: [
                                      Theme.of(context).colorScheme.primary,
                                      Theme.of(context).colorScheme.secondary,
                                    ],
                                  ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: _isLoading
                                ? []
                                : [
                                    BoxShadow(
                                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                                      blurRadius: 15,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _isLoading ? null : _saveProfile,
                              borderRadius: BorderRadius.circular(16),
                              child: Center(
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2.5,
                                        ),
                                      )
                                    : Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            Icons.save_rounded,
                                            color: Colors.white,
                                            size: 24,
                                          ),
                                          const SizedBox(width: 8),
                                          const Text(
                                            '儲存',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 18,
                                              fontWeight: FontWeight.w600,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}