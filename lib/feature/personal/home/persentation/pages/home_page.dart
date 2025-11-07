import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:tryzeon/shared/component/image_picker_helper.dart';
import 'package:tryzeon/shared/component/top_notification.dart';
import 'package:tryzeon/shared/component/confirmation_dialog.dart';
import 'package:tryzeon/feature/personal/home/data/avatar_service.dart';
import '../../data/tryon_service.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:tryzeon/shared/services/file_cache_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  String? _avatarPath;
  final List<String> _tryonImages = []; // 試穿後的圖片列表
  int _currentTryonIndex = -1; // 當前顯示的試穿圖片索引，-1表示沒有試穿圖片
  bool _isLoading = true;
  int? _customAvatarIndex; // 記錄哪張試穿照片被設為自訂 avatar

  @override
  void initState() {
    super.initState();
    _loadAvatar();
  }

  Future<void> virtualTryOnFromLocal() async {
    // Check if avatar is available
    if (_avatarPath == null) {
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

    if (clothingImage == null) return;

    setState(() {
      _isLoading = true;
    });

    // 如果有自訂 avatar，取得其 base64
    String? customAvatarBase64;
    if (_customAvatarIndex != null) {
      final avatarUrl = _tryonImages[_customAvatarIndex!];
      customAvatarBase64 = avatarUrl.split(',')[1];
    }

    final tryonResult = await TryonService.tryon(
      clothingImage,
      avatarBase64: customAvatarBase64,
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      // Check if success
      if (tryonResult.image != null) {
        setState(() {
          _tryonImages.add(tryonResult.image!);
          _currentTryonIndex = _tryonImages.length - 1;
        });

        TopNotification.show(
          context,
          message: '試穿成功！',
          type: NotificationType.success,
        );
      } else {
        TopNotification.show(
          context,
          message: tryonResult.error ?? '發生錯誤',
          type: NotificationType.error,
        );
      }
    }
  }

  Future<void> virtualTryOnFromStorage(String storagePath) async {
    setState(() {
      _isLoading = true;
    });

    // 如果有自訂 avatar，取得其 base64
    String? customAvatarBase64;
    if (_customAvatarIndex != null && _customAvatarIndex! < _tryonImages.length) {
      final avatarUrl = _tryonImages[_customAvatarIndex!];
      customAvatarBase64 = avatarUrl.split(',')[1];
    }

    final tryonResult = await TryonService.tryonFromStorage(
      storagePath,
      avatarBase64: customAvatarBase64,
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      // Check if success
      if (tryonResult.image != null) {
        setState(() {
          _tryonImages.add(tryonResult.image!);
          _currentTryonIndex = _tryonImages.length - 1;
        });

        TopNotification.show(
          context,
          message: '試穿成功！',
          type: NotificationType.success,
        );
      } else {
        // Show error message from backend
        TopNotification.show(
          context,
          message: tryonResult.error ?? '發生錯誤',
          type: NotificationType.error,
        );
      }
    }
  }

  Future<void> _loadAvatar() async {
    final path = await AvatarService.getAvatar();
    if (mounted) {
      setState(() {
        _avatarPath = path;
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
      final path = await AvatarService.uploadAvatar(imageFile);

      if (mounted) {
        setState(() {
          _avatarPath = path;
          _tryonImages.clear(); // 上傳新頭像時清除試穿圖片
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
    if (_currentTryonIndex >= 0 && _currentTryonIndex < _tryonImages.length) {
      return _tryonImages[_currentTryonIndex];
    }
    return _avatarPath;
  }

  Future<void> _downloadCurrentImage() async {
    try {
      final base64Url = _tryonImages[_currentTryonIndex];
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

  Future<void> _toggleAvatar() async {
    try {
      final isCurrentlySet = _customAvatarIndex == _currentTryonIndex;

      setState(() {
        if (isCurrentlySet) {
          // 取消設定
          _customAvatarIndex = null;
        } else {
          // 設定為 avatar
          _customAvatarIndex = _currentTryonIndex;
        }
      });

      if (mounted) {
        TopNotification.show(
          context,
          message: isCurrentlySet ? '已取消試穿形象' : '已設定為試穿形象',
          type: NotificationType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        TopNotification.show(
          context,
          message: '操作失敗：$e',
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
      final deletedIndex = _currentTryonIndex;

      setState(() {
        _tryonImages.removeAt(_currentTryonIndex);

        // 如果刪除的照片是自訂 avatar，清除設定
        if (_customAvatarIndex == deletedIndex) {
          _customAvatarIndex = null;
        } else if (_customAvatarIndex != null && _customAvatarIndex! > deletedIndex) {
          // 如果自訂 avatar 在刪除照片之後，索引需要 -1
          _customAvatarIndex = _customAvatarIndex! - 1;
        }

        // 調整當前索引
        if (_tryonImages.isEmpty) {
          // 如果沒有試穿照片了，回到原圖
          _currentTryonIndex = -1;
        } else if (_currentTryonIndex >= _tryonImages.length) {
          // 如果刪除的是最後一張，往前移一張
          _currentTryonIndex = _tryonImages.length - 1;
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

  Widget _buildMoreOptionsButton() {
    return Positioned(
      top: 16,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
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
                      _buildOptionButton(
                        title: '下載照片',
                        subtitle: '儲存到相簿',
                        icon: Icons.download_rounded,
                        onTap: () {
                          Navigator.pop(context);
                          _downloadCurrentImage();
                        },
                      ),
                      _buildOptionButton(
                        title: _customAvatarIndex == _currentTryonIndex
                            ? '取消我的形象'
                            : '設為我的形象',
                        subtitle: _customAvatarIndex == _currentTryonIndex
                            ? '取消使用此照片作為試穿形象'
                            : '使用此照片作為試穿形象',
                        icon: _customAvatarIndex == _currentTryonIndex
                            ? Icons.person_off_outlined
                            : Icons.person_outline_rounded,
                        onTap: () {
                          Navigator.pop(context);
                          _toggleAvatar();
                        },
                      ),
                      _buildOptionButton(
                        title: '刪除此試穿',
                        subtitle: '移除這張試穿照片',
                        icon: Icons.delete_outline_rounded,
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
          },
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
    );
  }

  Widget _buildOptionButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(subtitle),
      onTap: onTap,
    );
  }

  Widget _buildNavigationButtons() {
    return Positioned(
      left: 16,
      right: 16,
      bottom: 16,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 上一步按鈕
          _buildNavButton(
            icon: Icons.arrow_back_ios_rounded,
            isEnabled: _currentTryonIndex >= 0,
            onTap: _currentTryonIndex >= 0 ? _previousTryon : null,
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
                  ? '${_currentTryonIndex + 1} / ${_tryonImages.length}'
                  : '原圖',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          // 下一步按鈕
          _buildNavButton(
            icon: Icons.arrow_forward_ios_rounded,
            isEnabled: _currentTryonIndex < _tryonImages.length - 1,
            onTap: _currentTryonIndex < _tryonImages.length - 1 ? _nextTryon : null,
          ),
        ],
      ),
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required bool isEnabled,
    required VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isEnabled
                ? Colors.black.withValues(alpha: 0.5)
                : Colors.black.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            icon,
            color: isEnabled
                ? Colors.white
                : Colors.white.withValues(alpha: 0.5),
            size: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarImage(String? image) {
    if (image == null) {
      // No image - show default
      return Image.asset(
        'assets/images/profile/default.png',
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
      );
    } else if (image.startsWith('data:image')) {
      // Base64 data URL (tryon results)
      final base64String = image.split(',')[1];
      final bytes = base64Decode(base64String);
      return Image.memory(
        bytes,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
      );
    } else {
      // Load from file
      return FutureBuilder<File?>(
        future: FileCacheService.getFile(image),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data != null) {
            return Image.file(
              snapshot.data!,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.image_not_supported),
            );
          }
          return Center(child: CircularProgressIndicator());
        }
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
                            // 主要圖片
                            _buildAvatarImage(_currentDisplayUrl),

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
                                      ShaderMask(
                                        shaderCallback: (bounds) => const LinearGradient(
                                          colors: [
                                            Colors.white,
                                            Color(0xFFE0E0E0),
                                          ],
                                        ).createShader(bounds),
                                        child: const Text(
                                          '正在努力試穿中...',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 1.5,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                            // 更多選項按鈕（僅在顯示試穿結果時顯示）
                            if (!_isLoading && _currentTryonIndex >= 0)
                              _buildMoreOptionsButton(),

                            // 上一步/下一步按鈕（僅在有試穿結果時顯示）
                            if (!_isLoading && _tryonImages.isNotEmpty)
                              _buildNavigationButtons(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // 虛擬試穿按鈕
                Container(
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: _isLoading
                        ? LinearGradient(
                            colors: [Colors.grey[300]!, Colors.grey[400]!],
                          )
                        : LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Theme.of(context).colorScheme.secondary,
                              Theme.of(context).colorScheme.secondary.withValues(alpha: 0.8),
                            ],
                          ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: _isLoading
                        ? []
                        : [
                            BoxShadow(
                              color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _isLoading ? null : virtualTryOnFromLocal,
                      borderRadius: BorderRadius.circular(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.auto_awesome_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '虛擬試穿',
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
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}