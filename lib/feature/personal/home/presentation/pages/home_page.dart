import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gal/gal.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/presentation/dialogs/confirmation_dialog.dart';
import 'package:tryzeon/core/presentation/widgets/top_notification.dart';
import 'package:tryzeon/core/utils/image_picker_helper.dart';
import 'package:tryzeon/feature/personal/home/providers/providers.dart';
import 'package:tryzeon/feature/personal/profile/providers/providers.dart';
import 'package:typed_result/typed_result.dart';

class HomePageController {
  Future<void> Function(String clothesPath)? tryOnFromStorage;

  void dispose() {
    tryOnFromStorage = null;
  }
}

class HomePage extends HookConsumerWidget {
  const HomePage({super.key, this.controller});
  final HomePageController? controller;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final avatarAsync = ref.watch(avatarFileProvider);
    final tryonImages = useState<List<Uint8List>>([]);
    final currentTryonIndex = useState(-1);
    final isActionLoading = useState(false);
    final customAvatarIndex = useState<int?>(null);

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    Future<void> uploadAvatar() async {
      final File? imageFile = await ImagePickerHelper.pickImage(context);
      if (imageFile == null) return;

      isActionLoading.value = true;

      try {
        final profile = await ref.read(userProfileProvider.future);
        final result = await ref.read(updateUserProfileUseCaseProvider)(
          original: profile,
          target: profile,
          avatarFile: imageFile,
        );

        if (!context.mounted) return;

        if (result.isSuccess) {
          tryonImages.value = [];
          currentTryonIndex.value = -1;
          customAvatarIndex.value = null;
          ref.invalidate(userProfileProvider);
          TopNotification.show(
            context,
            message: '頭像上傳成功',
            type: NotificationType.success,
          );
        } else {
          TopNotification.show(
            context,
            message: result.getError()!,
            type: NotificationType.error,
          );
        }
      } catch (e) {
        if (!context.mounted) return;
        TopNotification.show(
          context,
          message: '頭像上傳失敗：${e.toString()}',
          type: NotificationType.error,
        );
      } finally {
        isActionLoading.value = false;
      }
    }

    Future<void> performTryOn({
      final String? clothesBase64,
      final String? clothesPath,
    }) async {
      // 如果有自訂 avatar，轉換為 base64
      String? customAvatarBase64;
      if (customAvatarIndex.value != null) {
        customAvatarBase64 = base64Encode(tryonImages.value[customAvatarIndex.value!]);
      }

      isActionLoading.value = true;

      final tryonUseCase = ref.read(tryonUseCaseProvider);
      final result = await tryonUseCase(
        customAvatarBase64: customAvatarBase64,
        clothesBase64: clothesBase64,
        clothesPath: clothesPath,
      );

      if (!context.mounted) return;

      isActionLoading.value = false;

      // Check if success
      if (result.isSuccess) {
        // 解碼 base64 並儲存為 bytes
        final base64String = result.get()!.imageBase64.split(',')[1];
        final imageBytes = base64Decode(base64String);

        tryonImages.value = [...tryonImages.value, imageBytes];
        currentTryonIndex.value = tryonImages.value.length - 1;

        TopNotification.show(context, message: '試穿成功！', type: NotificationType.success);
      } else {
        TopNotification.show(
          context,
          message: result.getError()!,
          type: NotificationType.error,
        );
      }
    }

    Future<void> tryOnFromLocal() async {
      final File? clothesImage = await ImagePickerHelper.pickImage(context);
      if (clothesImage == null) return;

      final clothesBytes = await clothesImage.readAsBytes();
      final clothesBase64 = base64Encode(clothesBytes);

      await performTryOn(clothesBase64: clothesBase64);
    }

    Future<void> tryOnFromStorage(final String clothesPath) async {
      await performTryOn(clothesPath: clothesPath);
    }

    void previousTryon() {
      currentTryonIndex.value--;
    }

    void nextTryon() {
      currentTryonIndex.value++;
    }

    Future<void> downloadCurrentImage() async {
      try {
        final imageBytes = tryonImages.value[currentTryonIndex.value];

        // 儲存到相簿
        await Gal.putImageBytes(
          imageBytes,
          name: 'tryzeon_${DateTime.now().millisecondsSinceEpoch}',
        );

        if (context.mounted) {
          TopNotification.show(
            context,
            message: '照片已儲存到相簿',
            type: NotificationType.success,
          );
        }
      } catch (e) {
        if (context.mounted) {
          TopNotification.show(context, message: '儲存失敗：$e', type: NotificationType.error);
        }
      }
    }

    Future<void> toggleAvatar() async {
      final isCurrentlySet = customAvatarIndex.value == currentTryonIndex.value;

      if (isCurrentlySet) {
        // 取消設定
        customAvatarIndex.value = null;
      } else {
        // 設定為 avatar
        customAvatarIndex.value = currentTryonIndex.value;
      }

      if (context.mounted) {
        TopNotification.show(
          context,
          message: isCurrentlySet ? '已取消試穿形象' : '已設定為試穿形象',
          type: NotificationType.success,
        );
      }
    }

    Future<void> deleteCurrentTryon() async {
      final confirmed = await ConfirmationDialog.show(
        context: context,
        content: '確定要刪除這張試穿照片嗎？',
        confirmText: '刪除',
      );

      if (confirmed == true) {
        final deletedIndex = currentTryonIndex.value;

        final newImages = List<Uint8List>.from(tryonImages.value);
        newImages.removeAt(deletedIndex);
        tryonImages.value = newImages;

        // 如果刪除的照片是自訂 avatar，清除設定
        if (customAvatarIndex.value == deletedIndex) {
          customAvatarIndex.value = null;
        } else if (customAvatarIndex.value != null &&
            customAvatarIndex.value! > deletedIndex) {
          // 如果自訂 avatar 在刪除照片之後，索引需要 -1
          customAvatarIndex.value = customAvatarIndex.value! - 1;
        }

        // 調整當前索引
        if (tryonImages.value.isEmpty) {
          // 如果沒有試穿照片了，回到原圖
          currentTryonIndex.value = -1;
        } else if (currentTryonIndex.value >= tryonImages.value.length) {
          // 如果刪除的是最後一張，往前移一張
          currentTryonIndex.value = tryonImages.value.length - 1;
        }
        // 否則保持當前索引，會自動顯示下一張

        if (context.mounted) {
          TopNotification.show(
            context,
            message: '已刪除試穿照片',
            type: NotificationType.success,
          );
        }
      }
    }

    useEffect(() {
      if (controller != null) {
        controller!.tryOnFromStorage = tryOnFromStorage;
        return () => controller!.tryOnFromStorage = null;
      }
      return null;
    }, [controller]);

    Widget buildOptionButton({
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

    Widget buildMoreOptionsButton() {
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
                        buildOptionButton(
                          title: '下載照片',
                          subtitle: '儲存到相簿',
                          icon: Icons.download_rounded,
                          onTap: () {
                            Navigator.pop(context);
                            downloadCurrentImage();
                          },
                        ),
                        buildOptionButton(
                          title: customAvatarIndex.value == currentTryonIndex.value
                              ? '取消我的形象'
                              : '設為我的形象',
                          subtitle: customAvatarIndex.value == currentTryonIndex.value
                              ? '取消使用此照片作為試穿形象'
                              : '使用此照片作為試穿形象',
                          icon: customAvatarIndex.value == currentTryonIndex.value
                              ? Icons.person_off_outlined
                              : Icons.person_outline_rounded,
                          onTap: () {
                            Navigator.pop(context);
                            toggleAvatar();
                          },
                        ),
                        buildOptionButton(
                          title: '刪除此試穿',
                          subtitle: '移除這張試穿照片',
                          icon: Icons.delete_outline_rounded,
                          onTap: () {
                            Navigator.pop(context);
                            deleteCurrentTryon();
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

    Widget buildNavButton({
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

    Widget buildNavigationButtons() {
      return Positioned(
        left: 16,
        right: 16,
        bottom: 16,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // 上一步按鈕
            buildNavButton(
              icon: Icons.arrow_back_ios_rounded,
              isEnabled: currentTryonIndex.value >= 0,
              onTap: currentTryonIndex.value >= 0 ? previousTryon : null,
            ),

            // 頁數指示器
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                currentTryonIndex.value >= 0
                    ? '${currentTryonIndex.value + 1} / ${tryonImages.value.length}'
                    : '原圖',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            // 下一步按鈕
            buildNavButton(
              icon: Icons.arrow_forward_ios_rounded,
              isEnabled: currentTryonIndex.value < tryonImages.value.length - 1,
              onTap: currentTryonIndex.value < tryonImages.value.length - 1
                  ? nextTryon
                  : null,
            ),
          ],
        ),
      );
    }

    Widget buildAvatarImage(final File? avatarFile) {
      // 如果有試穿圖片，顯示試穿圖片
      if (currentTryonIndex.value >= 0 &&
          currentTryonIndex.value < tryonImages.value.length) {
        return Image.memory(
          tryonImages.value[currentTryonIndex.value],
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.cover,
        );
      }

      // 沒有試穿圖片，顯示原始頭像
      if (avatarFile != null) {
        return Image.file(
          avatarFile,
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
          onRefresh: () async {
            ref.invalidate(userProfileProvider);
            ref.invalidate(avatarFileProvider);
            await ref.read(avatarFileProvider.future);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 標題
                    Text(
                      'Tryzeon',
                      style: textTheme.displayLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1.0,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 虛擬人偶容器
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.6,
                      child: GestureDetector(
                        onTap: uploadAvatar,
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
                            child: avatarAsync.when(
                              loading: () =>
                                  const Center(child: CircularProgressIndicator()),
                              error: (final error, final stack) => Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.error_outline_rounded,
                                      size: 48,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(height: 16),
                                    TextButton(
                                      onPressed: () {
                                        ref.invalidate(userProfileProvider);
                                        ref.invalidate(avatarFileProvider);
                                      },
                                      child: const Text('重試'),
                                    ),
                                  ],
                                ),
                              ),
                              data: (final avatarFile) => Stack(
                                children: [
                                  // 主要圖片
                                  buildAvatarImage(avatarFile),

                                  // 載入遮罩
                                  if (isActionLoading.value)
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
                                      child: const Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    ),

                                  // 更多選項按鈕
                                  if (!isActionLoading.value &&
                                      currentTryonIndex.value >= 0)
                                    buildMoreOptionsButton(),

                                  // 上一步/下一步按鈕
                                  if (!isActionLoading.value &&
                                      tryonImages.value.isNotEmpty)
                                    buildNavigationButtons(),
                                ],
                              ),
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
                        gradient: (isActionLoading.value || avatarAsync.isLoading)
                            ? LinearGradient(
                                colors: [
                                  colorScheme.surfaceContainer,
                                  colorScheme.surfaceContainerHigh,
                                ],
                              )
                            : LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [colorScheme.primary, colorScheme.secondary],
                              ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: (isActionLoading.value || avatarAsync.isLoading)
                            ? []
                            : [
                                BoxShadow(
                                  color: colorScheme.primary.withValues(alpha: 0.3),
                                  blurRadius: 15,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: (isActionLoading.value || avatarAsync.isLoading)
                              ? null
                              : tryOnFromLocal,
                          borderRadius: BorderRadius.circular(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.auto_awesome_rounded,
                                color: (isActionLoading.value || avatarAsync.isLoading)
                                    ? colorScheme.onSurfaceVariant
                                    : Colors.white,
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '虛擬試穿',
                                style: textTheme.titleMedium?.copyWith(
                                  color: (isActionLoading.value || avatarAsync.isLoading)
                                      ? colorScheme.onSurfaceVariant
                                      : Colors.white,
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
