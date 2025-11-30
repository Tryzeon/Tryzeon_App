import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:tryzeon/feature/personal/home/data/avatar_service.dart';
import 'package:tryzeon/shared/dialogs/confirmation_dialog.dart';
import 'package:tryzeon/shared/widgets/image_picker_helper.dart';
import 'package:tryzeon/shared/widgets/top_notification.dart';

import '../../data/tryon_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  File? _avatarFile;
  final List<Uint8List> _tryonImages = []; // 試穿後的圖片列表（已解碼的 bytes）
  int _currentTryonIndex = -1; // 當前顯示的試穿圖片索引，-1表示沒有試穿圖片
  bool _isLoading = true;
  int? _customAvatarIndex; // 記錄哪張試穿照片被設為自訂 avatar

  @override
  void initState() {
    super.initState();
    _loadAvatar();
  }

  /// 核心試穿邏輯 - 處理本地檔案或儲存路徑的試穿
  Future<void> _performTryOn({
    final String? clothesBase64,
    final String? clothesPath,
  }) async {
    if (_avatarFile == null) {
      TopNotification.show(context, message: '請先上傳您的照片', type: NotificationType.warning);
      return;
    }

    // 如果有自訂 avatar，轉換為 base64
    String? customAvatarBase64;
    if (_customAvatarIndex != null) {
      customAvatarBase64 = base64Encode(_tryonImages[_customAvatarIndex!]);
    }

    setState(() {
      _isLoading = true;
    });

    final result = await TryonService.tryon(
      avatarBase64: customAvatarBase64,
      clothesBase64: clothesBase64,
      clothesPath: clothesPath,
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      // Check if success
      if (result.isSuccess) {
        // 解碼 base64 並儲存為 bytes
        final base64String = result.data!.split(',')[1];
        final imageBytes = base64Decode(base64String);

        setState(() {
          _tryonImages.add(imageBytes);
          _currentTryonIndex = _tryonImages.length - 1;
        });

        TopNotification.show(context, message: '試穿成功！', type: NotificationType.success);
      } else {
        TopNotification.show(
          context,
          message: result.errorMessage!,
          type: NotificationType.error,
        );
      }
    }
  }

  /// 從本地選擇衣服進行試穿
  Future<void> tryOnFromLocal() async {
    final File? clothesImage = await ImagePickerHelper.pickImage(context);
    if (clothesImage == null) return;

    final clothesBytes = await clothesImage.readAsBytes();
    final clothesBase64 = base64Encode(clothesBytes);

    await _performTryOn(clothesBase64: clothesBase64);
  }

  /// 從儲存路徑進行試穿
  Future<void> tryOnFromStorage(final String clothesPath) async {
    await _performTryOn(clothesPath: clothesPath);
  }

  Future<void> _loadAvatar({final bool forceRefresh = false}) async {
    setState(() {
      _isLoading = true;
    });

    final result = await AvatarService.getAvatar(forceRefresh: forceRefresh);
    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (result.isSuccess) {
      setState(() {
        _avatarFile = result.data;
      });
    } else {
      TopNotification.show(
        context,
        message: result.errorMessage!,
        type: NotificationType.error,
      );
    }
  }

  Future<void> _uploadAvatar() async {
    final File? imageFile = await ImagePickerHelper.pickImage(context);
    if (imageFile == null) return;

    setState(() {
      _isLoading = true;
    });

    final result = await AvatarService.uploadAvatar(imageFile);
    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (result.isSuccess) {
      setState(() {
        _avatarFile = result.data;
        _tryonImages.clear();
        _currentTryonIndex = -1;
        _customAvatarIndex = null;
      });

      TopNotification.show(context, message: '頭像上傳成功', type: NotificationType.success);
    } else {
      TopNotification.show(
        context,
        message: result.errorMessage!,
        type: NotificationType.error,
      );
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

  Future<void> _downloadCurrentImage() async {
    try {
      final imageBytes = _tryonImages[_currentTryonIndex];

      // 儲存到相簿
      await Gal.putImageBytes(
        imageBytes,
        name: 'tryzeon_${DateTime.now().millisecondsSinceEpoch}',
      );

      if (mounted) {
        TopNotification.show(
          context,
          message: '照片已儲存到相簿',
          type: NotificationType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        TopNotification.show(context, message: '儲存失敗：$e', type: NotificationType.error);
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
        TopNotification.show(context, message: '操作失敗：$e', type: NotificationType.error);
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
        TopNotification.show(context, message: '已刪除試穿照片', type: NotificationType.success);
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
              builder: (final context) => Container(
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
            child: const Icon(Icons.more_vert_rounded, color: Colors.white, size: 24),
          ),
        ),
      ),
    );
  }

  Widget _buildOptionButton({
    required final String title,
    required final String subtitle,
    required final IconData icon,
    required final VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Theme.of(context).colorScheme.primary),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
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
    required final IconData icon,
    required final bool isEnabled,
    required final VoidCallback? onTap,
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
            color: isEnabled ? Colors.white : Colors.white.withValues(alpha: 0.5),
            size: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarImage() {
    // 如果有試穿圖片，顯示試穿圖片
    if (_currentTryonIndex >= 0 && _currentTryonIndex < _tryonImages.length) {
      return Image.memory(
        _tryonImages[_currentTryonIndex],
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
      );
    }

    // 沒有試穿圖片，顯示原始頭像
    if (_avatarFile != null) {
      return Image.file(
        _avatarFile!,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (final context, final error, final stackTrace) =>
            const Icon(Icons.image_not_supported),
      );
    }

    // 沒有頭像，顯示預設圖片
    return Image.asset(
      'assets/images/profile/default.png',
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.surface,
              Color.alphaBlend(
                colorScheme.secondary.withValues(alpha: 0.05),
                colorScheme.surface,
              ),
              Color.alphaBlend(
                colorScheme.primary.withValues(alpha: 0.1),
                colorScheme.surface,
              ),
            ],
          ),
        ),
        child: RefreshIndicator(
          onRefresh: () => _loadAvatar(forceRefresh: true),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                child: Column(
                  children: [
                    // 標題
                    ShaderMask(
                      shaderCallback: (final bounds) => LinearGradient(
                        colors: [colorScheme.primary, colorScheme.secondary],
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
                                colorScheme.surface,
                                colorScheme.surface.withValues(alpha: 0.9),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: colorScheme.primary.withValues(alpha: 0.15),
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
                                _buildAvatarImage(),

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
                                            color: colorScheme.secondary,
                                            strokeWidth: 3,
                                          ),
                                          const SizedBox(height: 16),
                                          ShaderMask(
                                            shaderCallback: (final bounds) =>
                                                LinearGradient(
                                                  colors: [
                                                    Colors.white,
                                                    colorScheme.surfaceContainer,
                                                  ],
                                                ).createShader(bounds),
                                            child: const Text(
                                              '再一下...就快好了',
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
                                colors: [
                                  colorScheme.surfaceContainer,
                                  colorScheme.surfaceContainerHigh,
                                ],
                              )
                            : LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  colorScheme.secondary,
                                  colorScheme.secondary.withValues(alpha: 0.8),
                                ],
                              ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: _isLoading
                            ? []
                            : [
                                BoxShadow(
                                  color: colorScheme.secondary.withValues(alpha: 0.3),
                                  blurRadius: 15,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _isLoading ? null : tryOnFromLocal,
                          borderRadius: BorderRadius.circular(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.auto_awesome_rounded,
                                color: colorScheme.onSecondary,
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '虛擬試穿',
                                style: textTheme.titleMedium?.copyWith(
                                  color: colorScheme.onSecondary,
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
        ),
      ),
    );
  }
}
