import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gal/gal.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/config/app_constants.dart';
import 'package:tryzeon/core/presentation/dialogs/confirmation_dialog.dart';
import 'package:tryzeon/core/presentation/widgets/error_view.dart';
import 'package:tryzeon/core/presentation/widgets/top_notification.dart';
import 'package:tryzeon/core/utils/app_logger.dart';
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
    final pageController = usePageController(initialPage: 0);

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Sync PageController with currentTryonIndex changes (from logic)
    useEffect(() {
      if (pageController.hasClients) {
        final targetPage = currentTryonIndex.value + 1;
        if (pageController.page?.round() != targetPage) {
          pageController.animateToPage(
            targetPage,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      }
      return null;
    }, [currentTryonIndex.value]);

    Future<void> uploadAvatar() async {
      final File? imageFile = await ImagePickerHelper.pickImage(context);
      if (imageFile == null) return;

      isActionLoading.value = true;

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
        TopNotification.show(context, message: '頭像上傳成功', type: NotificationType.success);
      } else {
        TopNotification.show(
          context,
          message: result.getError()!,
          type: NotificationType.error,
        );
      }
      isActionLoading.value = false;
    }

    Future<void> performTryOn({
      final String? clothesBase64,
      final String? clothesPath,
    }) async {
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

      if (result.isSuccess) {
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

    Future<void> downloadCurrentImage() async {
      try {
        final imageBytes = tryonImages.value[currentTryonIndex.value];

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
      } catch (e, stackTrace) {
        AppLogger.error('照片儲存失敗', e, stackTrace);
        if (context.mounted) {
          TopNotification.show(
            context,
            message: '儲存失敗，請檢查儲存權限',
            type: NotificationType.error,
          );
        }
      }
    }

    Future<void> toggleAvatar() async {
      final isCurrentlySet = customAvatarIndex.value == currentTryonIndex.value;

      if (isCurrentlySet) {
        customAvatarIndex.value = null;
      } else {
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

        if (customAvatarIndex.value == deletedIndex) {
          customAvatarIndex.value = null;
        } else if (customAvatarIndex.value != null &&
            customAvatarIndex.value! > deletedIndex) {
          customAvatarIndex.value = customAvatarIndex.value! - 1;
        }

        if (tryonImages.value.isEmpty) {
          currentTryonIndex.value = -1;
        } else if (currentTryonIndex.value >= tryonImages.value.length) {
          currentTryonIndex.value = tryonImages.value.length - 1;
        }

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
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        onTap: onTap,
      );
    }

    Widget buildMoreOptionsButton() {
      return ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            color: colorScheme.onSurface.withValues(alpha: 0.1),
            child: IconButton(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  builder: (final context) => SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
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
                );
              },
              icon: Icon(Icons.more_vert_rounded, color: colorScheme.onSurface),
            ),
          ),
        ),
      );
    }

    Widget buildPageIndicator() {
      // Bottom Center
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: colorScheme.surface.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.1)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (currentTryonIndex.value == -1)
              Text(
                '原圖',
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      blurRadius: 4.0,
                      color: colorScheme.surface.withValues(alpha: 0.45),
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              )
            else
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(tryonImages.value.length, (final index) {
                  final isSelected = currentTryonIndex.value == index;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: isSelected ? 12 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colorScheme.onSurface
                          : colorScheme.onSurface.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
          ],
        ),
      );
    }

    Widget buildTryOnButton() {
      return Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(30),
            onTap: (isActionLoading.value || avatarAsync.isLoading)
                ? null
                : tryOnFromLocal,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_awesome_rounded, color: colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    '虛擬試穿',
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      body: RefreshIndicator(
        onRefresh: () => refreshUserProfile(ref),
        edgeOffset: MediaQuery.of(context).padding.top,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Background Image Layer - wrapped in scrollable for RefreshIndicator
            SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.of(context).size.height,
                child: GestureDetector(
                  onTap: uploadAvatar,
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: colorScheme.surface, // Fallback
                    child: avatarAsync.when(
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (final error, final stack) => Center(
                        child: ErrorView(
                          message: error.toString(),
                          onRetry: () => Future.wait([
                            ref.refresh(userProfileProvider.future),
                            ref.refresh(avatarFileProvider.future),
                          ]),
                        ),
                      ),
                      data: (final avatarFile) {
                        return PageView.builder(
                          controller: pageController,
                          onPageChanged: (final index) {
                            currentTryonIndex.value = index - 1;
                          },
                          itemCount: tryonImages.value.length + 1,
                          itemBuilder: (final context, final index) {
                            ImageProvider imageProvider;
                            if (index > 0) {
                              imageProvider = MemoryImage(tryonImages.value[index - 1]);
                            } else if (avatarFile != null) {
                              imageProvider = FileImage(avatarFile);
                            } else {
                              imageProvider = const AssetImage(
                                AppConstants.defaultProfileImage,
                              );
                            }

                            return Container(
                              decoration: BoxDecoration(
                                image: DecorationImage(
                                  image: imageProvider,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              child: Stack(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          colorScheme.surface.withValues(alpha: 0.3),
                                          Colors.transparent,
                                          colorScheme.surface.withValues(alpha: 0.3),
                                        ],
                                        stops: const [0.0, 0.4, 1.0],
                                      ),
                                    ),
                                  ),
                                  if (avatarFile == null && index == 0)
                                    Align(
                                      alignment: const Alignment(0, 0.5),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(20),
                                        child: BackdropFilter(
                                          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 8,
                                            ),
                                            color: colorScheme.surface.withValues(
                                              alpha: 0.3,
                                            ),
                                            child: Text(
                                              '點擊上傳照片',
                                              style: TextStyle(
                                                color: colorScheme.onSurface,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),

            // 2. Top Left Title Layer (Tryzeon)
            Positioned(
              top: 0,
              left: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(
                    'Tryzeon',
                    style: textTheme.displayLarge?.copyWith(
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.0,
                      shadows: [
                        Shadow(
                          blurRadius: 10.0,
                          color: colorScheme.primary.withValues(alpha: 0.5),
                          offset: const Offset(2, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // 3. Top Right Controls
            Positioned(
              top: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: !isActionLoading.value && currentTryonIndex.value >= 0
                      ? buildMoreOptionsButton()
                      : const SizedBox.shrink(),
                ),
              ),
            ),

            // 4. Bottom Layer (Navigation & Action) - Aware of Floating Nav Bar
            // We assume "floating nav bar" occupies bottom space.
            // Let's position things above it. Say bottom padding 100.
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Navigation Buttons (Left/Center aligned or just floating)
                  if (!isActionLoading.value && tryonImages.value.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: buildPageIndicator(),
                    ),

                  // Spacing for where the actual bottom bar would be
                  SizedBox(
                    height: MediaQuery.of(context).padding.bottom + 80,
                  ), // Approx floating bar height
                ],
              ),
            ),

            // 5. Bottom Right Floating Action Button (Try On)
            Positioned(
              bottom:
                  MediaQuery.of(context).padding.bottom +
                  30 +
                  (PlatformInfo.isIOS26OrHigher() ? 50 : 0),
              right: 20,
              child: buildTryOnButton(),
            ),

            // 6. Loading Overlay
            if (isActionLoading.value)
              Container(
                color: colorScheme.surface.withValues(alpha: 0.54),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: colorScheme.onSurface),
                      const SizedBox(height: 16),
                      Text(
                        '處理中...',
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          letterSpacing: 2,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
