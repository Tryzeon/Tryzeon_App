import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import '../widget/wardrobe_page.dart';
import 'package:tryzeon/shared/image_picker_helper.dart';
import 'package:tryzeon/feature/personal/home/data/avatar_service.dart';
import '../../data/tryon_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? _avatarUrl;
  bool _isUploading = false;
  bool _isLoading = true;
  bool _isTryingOn = false;

  @override
  void initState() {
    super.initState();
    _loadAvatar();
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
      _isUploading = true;
    });

    try {
      final url = await AvatarService.uploadAvatar(imageFile);

      if (mounted) {
        setState(() {
          _avatarUrl = url;
          _isUploading = false;
        });
      }
    } catch (e) {
      // 上傳失敗，顯示錯誤訊息並恢復原本的頭像
      if (mounted) {
        setState(() {
          _isUploading = false;
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

    if (clothingImage != null) {
      setState(() {
        _isTryingOn = true;
      });

      final tryonResult = await TryonService.uploadClothingForTryon(clothingImage, _avatarUrl);
      
      if (mounted) {
        setState(() {
          _isTryingOn = false;
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
        errorBuilder: (context, error, stackTrace) {
          return Image.asset(
            'assets/images/profile/default.png',
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
          );
        },
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // 標題
              const Text(
                '虛擬試衣間',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.brown,
                ),
              ),
              const SizedBox(height: 40),
              
              // 虛擬人偶
              Expanded(
                child: GestureDetector(
                  onTap: _uploadAvatar,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withValues(alpha: 0.3),
                          spreadRadius: 2,
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Stack(
                        children: [
                          if (_isLoading)
                            Container(
                              color: Colors.grey[200],
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            )
                          else if (_avatarUrl != null)
                            _buildAvatarImage(_avatarUrl!)
                          else
                            Image.asset(
                              'assets/images/profile/default.png',
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[300],
                                  child: const Icon(
                                    Icons.person,
                                    size: 100,
                                    color: Colors.grey,
                                  ),
                                );
                              },
                            ),
                          if (_isUploading)
                            Container(
                              color: Colors.black54,
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 40),
              
              // 按鈕區域
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // 衣櫃按鈕
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const WardrobePage(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.checkroom),
                    label: const Text('我的衣櫃'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.brown,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                  
                  // 虛擬試穿按鈕
                  ElevatedButton.icon(
                    onPressed: _isTryingOn ? null : _virtualTryon,
                    icon: _isTryingOn 
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.add_a_photo),
                    label: Text(_isTryingOn ? '處理中...' : '虛擬試穿'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.brown[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}