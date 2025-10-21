import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import '../widget/wardrobe_page.dart';
import 'package:tryzeon/shared/component/image_picker_helper.dart';
import 'package:tryzeon/feature/personal/home/data/avatar_service.dart';
import '../../data/tryon_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  String? _avatarUrl;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAvatar();
  }

  Future<void> startTryonFromProduct(String productImageUrl) async {
    setState(() {
      _isLoading = true;
    });

    final tryonResult = await TryonService.tryonProduct(productImageUrl);

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (tryonResult != null) {
          _avatarUrl = tryonResult;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('虛擬試穿失敗，請稍後再試')),
          );
        }
      });
    }
  }

  Future<void> _loadAvatar() async {
    final url = await AvatarService.getAvatar();
    if (mounted) {
      setState(() {
        _avatarUrl = url;
        _isLoading = false;
      });
    }
  }

  Future<void> _uploadAvatar() async {
    final File? imageFile = await ImagePickerHelper.pickImage(
      context,
    );
    if (imageFile == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final url = await AvatarService.uploadAvatar(imageFile);

      if (mounted) {
        setState(() {
          _avatarUrl = url;
          _isLoading = false;
        });
      }
    } catch (e) {
      // 上傳失敗，顯示錯誤訊息並恢復原本的頭像
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('上傳失敗，請稍後再試')),
        );
      }
    }
  }

  Future<void> _virtualTryon() async {
    // Check if avatar is available
    if (_avatarUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('請先上傳您的照片')),
      );
      return;
    }

    final File? clothingImage = await ImagePickerHelper.pickImage(
      context,
    );

    if (clothingImage == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('無法獲取您上傳的照片')),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final tryonResult = await TryonService.tryon(clothingImage);
    
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (tryonResult != null) {
          // Update avatar to show tryon result
          _avatarUrl = tryonResult;
        } else {
          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('虛擬試穿失敗，請稍後再試')),
          );
        }
      });
    }
  }

  Widget _buildAvatarImage(String url) {
    // Check if it's a base64 data URL
    if (url.startsWith('data:image')) {
      // Extract base64 string from data URL
      final base64String = url.split(',')[1];
      final bytes = base64Decode(base64String);
      return Image.memory(
        bytes,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover
      );
    } else if (url.startsWith('/')) {
      // Local file path
      return Image.file(
        File(url),
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Image.asset(
            'assets/images/profile/default.png',
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
          );
        },
      );
    } else {
      // Regular URL
      return Image.network(
        url,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
      );
    }
  }

  @override
  void dispose() {
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
                Theme.of(context).colorScheme.secondary.withValues(alpha: 0.05),
                Theme.of(context).colorScheme.surface,
              ),
              Color.alphaBlend(
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                Theme.of(context).colorScheme.surface,
              ),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Column(
              children: [
                // 標題
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.secondary,
                    ],
                  ).createShader(bounds),
                  child: const Text(
                    '享受時尚，自由穿搭',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // 虛擬人偶容器
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: GestureDetector(
                    onTap: _uploadAvatar,
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(32),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white,
                            Colors.white.withValues(alpha: 0.9),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                            spreadRadius: 0,
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(32),
                        child: Stack(
                          children: [
                            // 主要圖片
                            if (_avatarUrl != null)
                              _buildAvatarImage(_avatarUrl!)
                            else
                              Image.asset(
                                'assets/images/profile/default.png',
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Colors.grey[200]!,
                                          Colors.grey[300]!,
                                        ],
                                      ),
                                    ),
                                    child: Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.person_outline_rounded,
                                            size: 80,
                                            color: Colors.grey[400],
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            '點擊上傳您的照片',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),

                            // 載入遮罩
                            if (_isLoading)
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.black.withValues(alpha: 0.6),
                                      Colors.black.withValues(alpha: 0.8),
                                    ],
                                  ),
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      CircularProgressIndicator(
                                        color: Theme.of(context).colorScheme.secondary,
                                        strokeWidth: 3,
                                      ),
                                      const SizedBox(height: 16),
                                      const Text(
                                        '處理中...',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                            // 上傳提示（當沒有載入時顯示）
                            if (!_isLoading && _avatarUrl != null)
                              Positioned(
                                top: 16,
                                right: 16,
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt_outlined,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // 按鈕區域
                Row(
                  children: [
                    // 衣櫃按鈕
                    Expanded(
                      child: _buildActionButton(
                        context: context,
                        icon: Icons.checkroom_rounded,
                        label: '我的衣櫃',
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Theme.of(context).colorScheme.primary,
                            Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
                          ],
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const WardrobePage(),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(width: 16),

                    // 虛擬試穿按鈕
                    Expanded(
                      child: _buildActionButton(
                        context: context,
                        icon: Icons.auto_awesome_rounded,
                        label: '虛擬試穿',
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Theme.of(context).colorScheme.secondary,
                            Theme.of(context).colorScheme.secondary.withValues(alpha: 0.8),
                          ],
                        ),
                        onPressed: _isLoading ? null : _virtualTryon,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Gradient gradient,
    required VoidCallback? onPressed,
  }) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        gradient: onPressed == null
            ? LinearGradient(
                colors: [Colors.grey[300]!, Colors.grey[400]!],
              )
            : gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: onPressed == null
            ? []
            : [
                BoxShadow(
                  color: gradient.colors.first.withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}