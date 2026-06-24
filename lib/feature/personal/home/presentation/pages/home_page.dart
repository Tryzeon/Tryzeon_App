import 'dart:convert';
import 'dart:io';

import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gal/gal.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tryzeon/core/config/app_constants.dart';
import 'package:tryzeon/core/error/failures.dart';
import 'package:tryzeon/core/extensions/failure_extension.dart';
import 'package:tryzeon/core/presentation/dialogs/upgrade_dialog.dart';
import 'package:tryzeon/core/presentation/widgets/app_action_sheet.dart';
import 'package:tryzeon/core/presentation/widgets/app_confirm_dialog.dart';
import 'package:tryzeon/core/presentation/widgets/app_snack_bar.dart';
import 'package:tryzeon/core/presentation/widgets/error_view.dart';
import 'package:tryzeon/core/presentation/widgets/top_notification.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/core/utils/app_logger.dart';
import 'package:tryzeon/core/utils/image_picker_helper.dart';
import 'package:tryzeon/core/utils/image_watermark_helper.dart';
import 'package:tryzeon/feature/personal/home/presentation/widgets/home_primary_action_button.dart';
import 'package:tryzeon/feature/personal/home/presentation/widgets/try_on_avatar_badge.dart';
import 'package:tryzeon/feature/personal/home/presentation/widgets/try_on_gallery.dart';
import 'package:tryzeon/feature/personal/home/presentation/widgets/try_on_indicator.dart';
import 'package:tryzeon/feature/personal/home/providers/tryon_gallery_provider.dart';
import 'package:tryzeon/feature/personal/main/tryon_coordinator.dart';
import 'package:tryzeon/feature/personal/profile/providers/personal_profile_providers.dart';
import 'package:tryzeon/feature/personal/settings/providers/settings_providers.dart';
import 'package:tryzeon/feature/personal/subscription/presentation/providers/subscription_capabilities_provider.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_garment.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_image_source.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_mode.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_params.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_result.dart';
import 'package:tryzeon/feature/personal/tryon/providers/tryon_providers.dart';
import 'package:typed_result/typed_result.dart';

class HomePage extends HookConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final avatarAsync = ref.watch(avatarFileProvider);
    final galleryState = ref.watch(tryonGalleryProvider);
    final galleryNotifier = ref.read(tryonGalleryProvider.notifier);
    final isUploadingAvatar = useState(false);
    final pageController = usePageController(initialPage: 0);

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final currentIndex = galleryState.currentIndex;
    final isCurrentTheAvatar = galleryState.isCurrentTheAvatar;

    useEffect(() {
      if (pageController.hasClients) {
        final targetPage = currentIndex + 1;
        if (pageController.page?.round() != targetPage) {
          pageController.animateToPage(
            targetPage,
            duration: AppDuration.slow,
            curve: AppCurves.standard,
          );
        }
      }
      return null;
    }, [currentIndex]);

    Future<void> uploadAvatar() async {
      final File? imageFile = await ImagePickerHelper.pickImage(
        context,
        title: '選擇模特來源',
        hint: '建議上傳短袖短褲的正面全身照。',
      );
      if (imageFile == null) return;

      isUploadingAvatar.value = true;

      try {
        // Upload
        final profile = await ref.read(userProfileProvider.future);
        if (profile == null) return;

        final result = await ref.read(updateUserAvatarUseCaseProvider)(
          avatarFile: imageFile,
          previousAvatarPath: profile.avatarPath,
        );

        if (!context.mounted) return;

        if (result.isSuccess) {
          ref.invalidate(userProfileProvider);
          ref.invalidate(avatarFileProvider);
          await ref.read(avatarFileProvider.future);
        } else {
          TopNotification.show(
            context,
            message: result.getError()!.displayMessage(context),
          );
        }
      } catch (e, stackTrace) {
        AppLogger.error('Failed to upload avatar', e, stackTrace);
        if (context.mounted) {
          TopNotification.show(context, message: '上傳照片失敗，請稍後再試');
        }
      } finally {
        if (context.mounted) {
          isUploadingAvatar.value = false;
        }
      }
    }

    Future<Uint8List> downloadBytes(final String url) async {
      final file = await DefaultCacheManager().getSingleFile(url);
      return file.readAsBytes();
    }

    Future<void> performTryOn({
      required final List<TryOnGarment> garments,
      final TryOnMode mode = TryOnMode.image,
    }) async {
      String? customAvatarBase64;
      final customAvatarUrl = galleryState.customAvatarResult?.imageUrl;
      if (customAvatarUrl != null && customAvatarUrl.isNotEmpty) {
        try {
          final bytes = await downloadBytes(customAvatarUrl);
          customAvatarBase64 = base64Encode(bytes);
        } catch (e, stackTrace) {
          AppLogger.error('Failed to download custom avatar', e, stackTrace);
          if (context.mounted) {
            TopNotification.show(context, message: '無法載入照片，請重新試穿');
          }
          return;
        }
      }

      final profile = await ref.read(userProfileProvider.future);
      final defaultAvatarPath = profile?.avatarPath;

      // Custom avatar wins; otherwise use the profile avatar path (the backend
      // fetches it directly, so a failed local preview must not block try-on).
      final TryOnImageSource? avatar = customAvatarBase64 != null
          ? TryOnImageSource.base64(customAvatarBase64)
          : (defaultAvatarPath != null && defaultAvatarPath.isNotEmpty)
          ? TryOnImageSource.path(defaultAvatarPath)
          : null;
      if (avatar == null) {
        if (context.mounted) {
          TopNotification.show(context, message: '請先上傳個人照片才能開始試穿呦！');
        }
        return;
      }

      final requestId = UniqueKey().toString();
      final placeholderResult = TryonResult(id: requestId, mode: mode, isLoading: true);
      galleryNotifier.addPlaceholder(placeholderResult);

      String? scenePrompt;
      String? transitionPrompt;
      if (mode == TryOnMode.video) {
        final promptConfig = await ref.read(videoPromptConfigProvider.future);
        scenePrompt = promptConfig.scenePrompt;
        transitionPrompt = promptConfig.transitionPrompt;
      }

      final result = await ref
          .read(tryonActionProvider.notifier)
          .execute(
            TryOnParams(
              requestId: requestId,
              avatar: avatar,
              garments: garments,
              mode: mode,
              scenePrompt: scenePrompt,
              transitionPrompt: transitionPrompt,
            ),
          );

      if (!context.mounted) return;

      if (result.isSuccess) {
        final tryonResult = result.get()!.copyWith(isLoading: false);
        galleryNotifier.replaceById(requestId, tryonResult);
        HapticFeedback.heavyImpact();
      } else {
        galleryNotifier.removeById(requestId);

        final failure = result.getError()!;
        if (failure is RateLimitFailure) {
          final isVideo = mode == TryOnMode.video;
          UpgradeDialog.show(
            context,
            title: isVideo ? '影片試穿次數已達上限' : '試穿次數已達上限',
            content: isVideo
                ? '您的今日影片試穿次數已達上限\n升級至更高方案以獲得更多影片次數！'
                : '您的今日試穿次數已達上限\n升級至更高方案以獲得更多次數！',
          );
        } else {
          TopNotification.show(context, message: failure.displayMessage(context));
        }
      }
    }

    Future<void> tryOnFromLocal() async {
      final File? clothesImage = await ImagePickerHelper.pickImage(
        context,
        title: '選擇服飾來源',
        hint: '建議上傳乾淨背景、單件服飾的清晰照片。',
      );
      if (clothesImage == null) return;

      final clothesBytes = await clothesImage.readAsBytes();
      final clothesBase64 = base64Encode(clothesBytes);
      performTryOn(
        garments: [
          TryOnGarment(images: [TryOnImageSource.base64(clothesBase64)]),
        ],
        mode: TryOnMode.image,
      );
    }

    Future<void> tryOnFromStorage(
      final List<String> clothesPaths, {
      final TryOnMode mode = TryOnMode.image,
    }) async {
      performTryOn(
        garments: [
          TryOnGarment(images: clothesPaths.map(TryOnImageSource.path).toList()),
        ],
        mode: mode,
      );
    }

    Future<void> downloadVideo(final TryonResult result) async {
      final videoUrl = result.videoUrl;
      if (videoUrl == null || videoUrl.isEmpty) {
        throw Exception('Video URL is missing');
      }

      // 1. Download to temp file
      final tempDir = await getTemporaryDirectory();
      final tempPath =
          '${tempDir.path}/tryon_${DateTime.now().millisecondsSinceEpoch}.mp4';

      try {
        final dio = Dio();
        await dio.download(result.videoUrl!, tempPath);

        // 2. Save to gallery
        await Gal.putVideo(tempPath);

        if (context.mounted) {
          AppSnackBar.show(context, message: '影片已儲存到相簿');
        }
      } finally {
        // 3. Clean up temp file
        final file = File(tempPath);
        if (await file.exists()) {
          await file.delete();
        }
      }
    }

    Future<void> downloadImage(final TryonResult result) async {
      final imageUrl = result.imageUrl;
      if (imageUrl == null || imageUrl.isEmpty) {
        throw Exception('Image URL is missing');
      }

      final originalBytes = await downloadBytes(imageUrl);
      Uint8List imageToSave = originalBytes;

      final capabilities = await ref.read(subscriptionCapabilitiesProvider.future);
      if (capabilities.requiresWatermark) {
        imageToSave = await ImageWatermarkHelper.addWatermark(originalBytes);
      }

      await Gal.putImageBytes(
        imageToSave,
        name: 'tryzeon_${DateTime.now().millisecondsSinceEpoch}',
      );

      if (context.mounted) {
        AppSnackBar.show(context, message: '照片已儲存到相簿');
      }
    }

    Future<void> downloadCurrentMedia() async {
      try {
        final result = galleryState.currentResult;
        if (result == null) return;

        if (result.mode == TryOnMode.video) {
          await downloadVideo(result);
        } else {
          await downloadImage(result);
        }
      } catch (e, stackTrace) {
        AppLogger.error('Failed to save media', e, stackTrace);
        if (context.mounted) {
          TopNotification.show(context, message: '儲存失敗，請檢查儲存權限');
        }
      }
    }

    void toggleAvatar() {
      galleryNotifier.toggleAvatarForCurrent();
    }

    Future<void> deleteCurrentTryon() async {
      final result = await showAppOkCancelDialog(
        context: context,
        message: '確定要刪除這張試穿照片嗎？',
        okLabel: '刪除',
        cancelLabel: '取消',
        isDestructiveAction: true,
      );

      if (result == OkCancelResult.ok) {
        galleryNotifier.deleteCurrent();
      }
    }

    final coordinator = ref.read(tryOnCoordinatorProvider);
    useEffect(() {
      coordinator.bindTryOnFromStorage(tryOnFromStorage);
      return () => coordinator.unbindTryOnFromStorage(tryOnFromStorage);
    });

    final bottomOffset =
        MediaQuery.paddingOf(context).bottom +
        (PlatformInfo.isIOS26OrHigher() ? AppSpacing.iosTabBarHeight : 0);

    final currentResult = galleryState.currentResult;
    final isAvatarPage = currentIndex == -1;
    final isResultLoading = currentResult?.isLoading ?? false;

    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      body: RefreshIndicator(
        onRefresh: () => refreshUserProfile(ref),
        edgeOffset: MediaQuery.of(context).padding.top,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Background Image Layer — wrapped in scrollable for RefreshIndicator
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
                      message: error.displayMessage(context),
                      onRetry: () => ref.invalidate(userProfileProvider),
                    ),
                  ),
                  data: (final avatarFile) => TryOnGallery(
                    pageController: pageController,
                    onPageChanged: (final index) {
                      final resultIndex = index - 1;
                      final id =
                          (resultIndex >= 0 && resultIndex < galleryState.images.length)
                          ? galleryState.images[resultIndex].id
                          : null;
                      galleryNotifier.setCurrentId(id);
                    },
                    tryonResults: galleryState.images,
                    avatarFile: avatarFile,
                    isUploadingAvatar: isUploadingAvatar.value,
                  ),
                ),
              ),
            ),

            // 2. Top Left — Tryzeon Logo (transparent mark)
            Positioned(
              top: MediaQuery.paddingOf(context).top + AppSpacing.sm,
              left: AppSpacing.lg,
              child: Image.asset(
                AppConstants.logoWordmark,
                height: 28,
                fit: BoxFit.contain,
              ),
            ),

            // 3. Top Right — Avatar Badge + More Options (parallel).
            // Hidden only while a try-on is loading.
            if (!isResultLoading)
              Positioned(
                top: MediaQuery.paddingOf(context).top + AppSpacing.xs,
                right: AppSpacing.md,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    TryOnAvatarBadge(isVisible: isCurrentTheAvatar),
                    const SizedBox(width: AppSpacing.sm),
                    IconButton(
                      icon: Icon(Icons.more_vert_rounded, color: colorScheme.onPrimary),
                      onPressed: () => showAppActionSheet(
                        context,
                        actions: isAvatarPage
                            ? [
                                AppMenuAction(
                                  icon: Icons.swap_horiz_rounded,
                                  title: '更換模特圖片',
                                  subtitle: '上傳照片更換試穿模特',
                                  onTap: uploadAvatar,
                                ),
                              ]
                            : [
                                AppMenuAction(
                                  icon: Icons.download_rounded,
                                  title: '下載',
                                  subtitle: '儲存到相簿',
                                  onTap: downloadCurrentMedia,
                                ),
                                if (currentResult?.mode == TryOnMode.image)
                                  AppMenuAction(
                                    icon: isCurrentTheAvatar
                                        ? Icons.person_off_outlined
                                        : Icons.person_outline_rounded,
                                    title: isCurrentTheAvatar ? '取消我的形象' : '設為我的形象',
                                    subtitle: isCurrentTheAvatar
                                        ? '取消使用此照片作為試穿形象'
                                        : '使用此照片作為試穿形象',
                                    onTap: toggleAvatar,
                                  ),
                                AppMenuAction(
                                  icon: Icons.delete_outline_rounded,
                                  title: '刪除此試穿',
                                  subtitle: '移除這張試穿照片',
                                  onTap: deleteCurrentTryon,
                                  isDestructive: true,
                                ),
                              ],
                      ),
                    ),
                  ],
                ),
              ),

            // 4. Bottom Left — Indicator (white floating lines)
            if (!isAvatarPage)
              Positioned(
                bottom: bottomOffset + AppSpacing.xl,
                left: AppSpacing.xxl,
                child: TryOnIndicator(
                  currentTryonIndex: currentIndex,
                  tryonImagesCount: galleryState.images.length,
                ),
              ),

            // 5. Bottom Right — Try On Button (dark glassmorphism pill)
            avatarAsync.maybeWhen(
              data: (final avatarFile) {
                final hasAvatar = avatarFile != null;
                return Positioned(
                  bottom: bottomOffset + AppSpacing.lg,
                  right: AppSpacing.lg,
                  child: HomePrimaryActionButton(
                    label: hasAvatar ? '虛擬試穿' : '上傳照片',
                    icon: hasAvatar ? Icons.auto_awesome_rounded : Icons.upload_rounded,
                    isDisabled: isUploadingAvatar.value,
                    onTap: hasAvatar ? tryOnFromLocal : uploadAvatar,
                  ),
                );
              },
              orElse: () => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
