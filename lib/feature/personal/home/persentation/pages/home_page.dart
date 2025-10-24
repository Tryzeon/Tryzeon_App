import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import '../widget/wardrobe_page.dart';
import 'package:tryzeon/shared/component/image_picker_helper.dart';
import 'package:tryzeon/shared/component/top_notification.dart';
import 'package:tryzeon/shared/component/confirmation_dialog.dart';
import 'package:tryzeon/feature/personal/home/data/avatar_service.dart';
import '../../data/tryon_service.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  String? _avatarUrl;
  final List<String> _tryonAvatarUrls = []; // 試穿後的圖片列表
  int _currentTryonIndex = -1; // 當前顯示的試穿圖片索引，-1表示沒有試穿圖片
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAvatar();
  }

  Future<void> _virtualTryOn() async {
    // Check if avatar is available
    if (_avatarUrl == null) {
      TopNotification.show(
        context,
        message: '請先上傳您的照片',
        type: NotificationType.warning,
      );
      return;
    }

    final File? clothingImage = await ImagePickerHelper.pickImage(
      context,
    );

    if (clothingImage == null) {
      if (mounted) {
        TopNotification.show(
          context,
          message: '無法獲取您上傳的照片',
          type: NotificationType.error,
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
          _tryonAvatarUrls.add(tryonResult);
          _currentTryonIndex = _tryonAvatarUrls.length - 1;
        } else {
          // Show error message
          TopNotification.show(
            context,
            message: '虛擬試穿失敗，請稍後再試',
            type: NotificationType.error,
          );
        }
      });
    }
  }

  Future<void> virtualTryOnProduct(String productImageUrl) async {
    setState(() {
      _isLoading = true;
    });

    final tryonResult = await TryonService.tryonProduct(productImageUrl);

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (tryonResult != null) {
          _tryonAvatarUrls.add(tryonResult);
          _currentTryonIndex = _tryonAvatarUrls.length - 1;
        } else {
          TopNotification.show(
            context,
            message: '虛擬試穿失敗，請稍後再試',
            type: NotificationType.error,
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
          _tryonAvatarUrls.clear(); // 上傳新頭像時清除試穿圖片
          _currentTryonIndex = -1;
          _isLoading = false;
        });
      }
    } catch (e) {
      // 上傳失敗，顯示錯誤訊息並恢復原本的頭像
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        TopNotification.show(
          context,
          message: '上傳失敗，請稍後再試',
          type: NotificationType.error,
        );
      }
    }
  }

  void _previousTryon() {
    setState(() {
      _currentTryonIndex--;
    });
  }

  void _nextTryon() {
    setState(() {
      _currentTryonIndex++;
    });
  }

  String? get _currentDisplayUrl {
    if (_currentTryonIndex >= 0 && _currentTryonIndex < _tryonAvatarUrls.length) {
      return _tryonAvatarUrls[_currentTryonIndex];
    }
    return _avatarUrl;
  }

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.download_rounded,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                title: const Text(
                  '下載照片',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: const Text('儲存到相簿'),
                onTap: () {
                  Navigator.pop(context);
                  _downloadCurrentImage();
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.delete_outline_rounded,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                title: const Text(
                  '刪除此試穿',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: const Text('移除這張試穿照片'),
                onTap: () {
                  Navigator.pop(context);
                  _deleteCurrentTryon();
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _downloadCurrentImage() async {
    try {
      final base64Url = _tryonAvatarUrls[_currentTryonIndex];
      final base64String = base64Url.split(',')[1];
      final imageBytes = base64Decode(base64String);

      // 儲存到相簿
      final result = await ImageGallerySaver.saveImage(
        imageBytes,
        quality: 100,
        name: 'tryzeon_${DateTime.now().millisecondsSinceEpoch}',
      );

      if (mounted) {
        if (result != null && result['isSuccess'] == true) {
          TopNotification.show(
            context,
            message: '照片已儲存到相簿',
            type: NotificationType.success,
          );
        } else {
          TopNotification.show(
            context,
            message: '儲存失敗，請稍後再試',
            type: NotificationType.error,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        TopNotification.show(
          context,
          message: '儲存失敗：$e',
          type: NotificationType.error,
        );
      }
    }
  }

  Future<void> _deleteCurrentTryon() async {
    final confirmed = await ConfirmationDialog.show(
      context: context,
      content: '確定要刪除這張試穿照片嗎？',
      confirmText: '刪除',
    );

    if (confirmed == true) {
      setState(() {
        _tryonAvatarUrls.removeAt(_currentTryonIndex);

        // 調整索引
        if (_tryonAvatarUrls.isEmpty) {
          // 如果沒有試穿照片了，回到原圖
          _currentTryonIndex = -1;
        } else if (_currentTryonIndex >= _tryonAvatarUrls.length) {
          // 如果刪除的是最後一張，往前移一張
          _currentTryonIndex = _tryonAvatarUrls.length - 1;
        }
        // 否則保持當前索引，會自動顯示下一張
      });

      if (mounted) {
        TopNotification.show(
          context,
          message: '已刪除試穿照片',
          type: NotificationType.success,
        );
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
                    'Tryzeon',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 3.0,
                      height: 1.2,
                      shadows: [
                        Shadow(
                          offset: Offset(2, 2),
                          blurRadius: 4,
                          color: Color.fromARGB(80, 0, 0, 0),
                        ),
                        Shadow(
                          offset: Offset(-1, -1),
                          blurRadius: 8,
                          color: Color.fromARGB(40, 255, 255, 255),
                        ),
                      ],
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
                            // 主要圖片 - 優先顯示試穿圖片
                            if (_currentDisplayUrl != null)
                              _buildAvatarImage(_currentDisplayUrl!)
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
                                        '正在努力穿衣中...',
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

                            // 更多選項按鈕（僅在顯示試穿結果時顯示）
                            if (!_isLoading && _currentTryonIndex >= 0)
                              Positioned(
                                top: 16,
                                right: 16,
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: _showMoreOptions,
                                    borderRadius: BorderRadius.circular(16),
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.5),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: const Icon(
                                        Icons.more_vert_rounded,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                            // 上一步/下一步按鈕（僅在有試穿結果時顯示）
                            if (!_isLoading && _tryonAvatarUrls.isNotEmpty)
                              Positioned(
                                left: 16,
                                right: 16,
                                bottom: 16,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    // 上一步按鈕
                                    Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: _currentTryonIndex >= 0 ? _previousTryon : null,
                                        borderRadius: BorderRadius.circular(16),
                                        child: Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: _currentTryonIndex >= 0
                                                ? Colors.black.withValues(alpha: 0.5)
                                                : Colors.black.withValues(alpha: 0.2),
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          child: Icon(
                                            Icons.arrow_back_ios_rounded,
                                            color: _currentTryonIndex >= 0
                                                ? Colors.white
                                                : Colors.white.withValues(alpha: 0.5),
                                            size: 24,
                                          ),
                                        ),
                                      ),
                                    ),

                                    // 頁數指示器
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.5),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Text(
                                        _currentTryonIndex >= 0
                                            ? '${_currentTryonIndex + 1} / ${_tryonAvatarUrls.length}'
                                            : '原圖',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),

                                    // 下一步按鈕
                                    Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: _currentTryonIndex < _tryonAvatarUrls.length - 1
                                            ? _nextTryon
                                            : null,
                                        borderRadius: BorderRadius.circular(16),
                                        child: Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: _currentTryonIndex < _tryonAvatarUrls.length - 1
                                                ? Colors.black.withValues(alpha: 0.5)
                                                : Colors.black.withValues(alpha: 0.2),
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          child: Icon(
                                            Icons.arrow_forward_ios_rounded,
                                            color: _currentTryonIndex < _tryonAvatarUrls.length - 1
                                                ? Colors.white
                                                : Colors.white.withValues(alpha: 0.5),
                                            size: 24,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
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
                        onPressed: _isLoading ? null : _virtualTryOn,
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