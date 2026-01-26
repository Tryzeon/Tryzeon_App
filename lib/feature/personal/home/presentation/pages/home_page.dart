import 'dart:convert';
import 'dart:io';

import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gal/gal.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/presentation/dialogs/confirmation_dialog.dart';
import 'package:tryzeon/core/presentation/widgets/error_view.dart';
import 'package:tryzeon/core/presentation/widgets/top_notification.dart';
import 'package:tryzeon/core/utils/app_logger.dart';
import 'package:tryzeon/core/utils/image_picker_helper.dart';
import 'package:tryzeon/feature/personal/home/presentation/widgets/try_on_action_button.dart';
import 'package:tryzeon/feature/personal/home/presentation/widgets/try_on_gallery.dart';
import 'package:tryzeon/feature/personal/home/presentation/widgets/try_on_indicator.dart';
import 'package:tryzeon/feature/personal/home/presentation/widgets/try_on_more_options_button.dart';
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
    final loadingIndices = useState<Set<int>>({});
    final currentTryonIndex = useState(-1);
    final customAvatarIndex = useState<int?>(null);
    final newAvatarFile = useState<File?>(null);
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

      // Optimistic update
      newAvatarFile.value = imageFile;

      // Upload
      final profile = await ref.read(userProfileProvider.future);
      final result = await ref.read(updateUserProfileUseCaseProvider)(
        original: profile,
        target: profile,
        avatarFile: imageFile,
      );

      if (!context.mounted) return;

      if (result.isSuccess) {
        await Future.wait([
          ref.refresh(userProfileProvider.future),
          ref.refresh(avatarFileProvider.future),
        ]);
      } else {
        TopNotification.show(
          context,
          message: result.getError()!,
          type: NotificationType.error,
        );
      }

      newAvatarFile.value = null;
    }

    Future<void> performTryOn({
      final String? clothesBase64,
      final String? clothesPath,
    }) async {
      Uint8List? placeholderBytes;

      // 1. Determine Placeholder Image
      if (customAvatarIndex.value != null &&
          customAvatarIndex.value! < tryonImages.value.length) {
        placeholderBytes = tryonImages.value[customAvatarIndex.value!];
      } else {
        final avatarFile = await ref.read(avatarFileProvider.future);
        if (avatarFile == null) {
          if (context.mounted) {
            TopNotification.show(
              context,
              message: '請先上傳您的照片',
              type: NotificationType.error,
            );
          }
          return;
        }
        placeholderBytes = await avatarFile.readAsBytes();
      }

      // 2. Prepare Request Data
      String? customAvatarBase64;
      if (customAvatarIndex.value != null &&
          customAvatarIndex.value! < tryonImages.value.length) {
        customAvatarBase64 = base64Encode(tryonImages.value[customAvatarIndex.value!]);
      }

      // 3. Optimistic Update (Add Placeholder)
      final newIndex = tryonImages.value.length;
      tryonImages.value = [...tryonImages.value, placeholderBytes];
      loadingIndices.value = {...loadingIndices.value, newIndex};
      currentTryonIndex.value = newIndex;

      // 4. API Call
      final tryonUseCase = ref.read(tryonUseCaseProvider);
      final result = await tryonUseCase(
        customAvatarBase64: customAvatarBase64,
        clothesBase64: clothesBase64,
        clothesPath: clothesPath,
      );

      if (!context.mounted) return;

      // 5. Handle Result
      if (result.isSuccess) {
        final base64String = result.get()!.imageBase64.split(',')[1];
        final imageBytes = base64Decode(base64String);

        tryonImages.value = [...tryonImages.value]..[newIndex] = imageBytes;
        loadingIndices.value = {...loadingIndices.value}..remove(newIndex);

        TopNotification.show(context, message: '試穿成功！', type: NotificationType.success);
      } else {
        // Failure: Remove placeholder
        tryonImages.value = [...tryonImages.value]..removeAt(newIndex);
        loadingIndices.value = {...loadingIndices.value}..remove(newIndex);
        currentTryonIndex.value = tryonImages.value.length - 1;

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
      performTryOn(clothesBase64: clothesBase64);
    }

    Future<void> tryOnFromStorage(final String clothesPath) async {
      performTryOn(clothesPath: clothesPath);
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
                child: avatarAsync.when(
                  skipLoadingOnReload: true,
                  skipError: true,
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (final error, final stack) => Center(
                    child: ErrorView(
                      message: error.toString(),
                      onRetry: () => refreshUserProfile(ref),
                    ),
                  ),
                  data: (final avatarFile) => TryOnGallery(
                    pageController: pageController,
                    onPageChanged: (final index) => currentTryonIndex.value = index - 1,
                    onUploadTap: uploadAvatar,
                    tryonImages: tryonImages.value,
                    loadingIndices: loadingIndices.value,
                    currentTryonIndex: currentTryonIndex.value,
                    avatarFile: newAvatarFile.value ?? avatarFile,
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
            if (currentTryonIndex.value >= 0 &&
                !loadingIndices.value.contains(currentTryonIndex.value))
              TryOnMoreOptionsButton(
                currentTryonIndex: currentTryonIndex.value,
                customAvatarIndex: customAvatarIndex.value,
                onDownload: downloadCurrentImage,
                onToggleAvatar: toggleAvatar,
                onDelete: deleteCurrentTryon,
              ),

            // 4. Bottom Layer (Navigation & Action) - Aware of Floating Nav Bar
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Navigation Buttons (Left/Center aligned or just floating)
                  if (tryonImages.value.isNotEmpty)
                    TryOnIndicator(
                      currentTryonIndex: currentTryonIndex.value,
                      tryonImagesCount: tryonImages.value.length,
                    ),

                  // Spacing for where the actual bottom bar would be
                  SizedBox(
                    height: MediaQuery.of(context).padding.bottom + 80,
                  ), // Approx floating bar height
                ],
              ),
            ),

            // 5. Try On Button
            Positioned(
              bottom:
                  MediaQuery.of(context).padding.bottom +
                  30 +
                  (PlatformInfo.isIOS26OrHigher() ? 50 : 0),
              right: 20,
              child: TryOnActionButton(
                onTap: tryOnFromLocal,
                isDisabled: avatarAsync.isLoading,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
