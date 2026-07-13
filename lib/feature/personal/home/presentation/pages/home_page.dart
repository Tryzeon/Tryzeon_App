import 'dart:io';

import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/config/app_constants.dart';
import 'package:tryzeon/core/extensions/failure_extension.dart';
import 'package:tryzeon/core/presentation/dialogs/upgrade_dialog.dart';
import 'package:tryzeon/core/presentation/widgets/app_action_sheet.dart';
import 'package:tryzeon/core/presentation/widgets/app_confirm_dialog.dart';
import 'package:tryzeon/core/presentation/widgets/app_snack_bar.dart';
import 'package:tryzeon/core/presentation/widgets/error_view.dart';
import 'package:tryzeon/core/presentation/widgets/top_notification.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/core/utils/image_picker_helper.dart';
import 'package:tryzeon/feature/personal/home/presentation/controllers/home_controller.dart';
import 'package:tryzeon/feature/personal/home/presentation/state/try_on_outcome.dart';
import 'package:tryzeon/feature/personal/home/presentation/widgets/home_primary_action_button.dart';
import 'package:tryzeon/feature/personal/home/presentation/widgets/try_on_avatar_badge.dart';
import 'package:tryzeon/feature/personal/home/presentation/widgets/try_on_gallery.dart';
import 'package:tryzeon/feature/personal/home/presentation/widgets/try_on_indicator.dart';
import 'package:tryzeon/feature/personal/home/providers/tryon_gallery_provider.dart';
import 'package:tryzeon/feature/personal/main/tryon_coordinator.dart';
import 'package:tryzeon/feature/personal/profile/providers/personal_profile_providers.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_mode.dart';
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
      final result = await ref
          .read(homeControllerProvider.notifier)
          .uploadAvatar(imageFile);
      if (!context.mounted) return;
      if (result.isFailure) {
        TopNotification.show(
          context,
          message: result.getError()!.displayMessage(context),
        );
      }
      isUploadingAvatar.value = false;
    }

    void handleTryOnOutcome(final TryOnOutcome outcome) {
      if (!context.mounted) return;
      switch (outcome) {
        case TryOnSucceeded():
          HapticFeedback.heavyImpact();
        case TryOnAvatarMissing():
          TopNotification.show(context, message: '請先上傳個人照片才能開始試穿呦！');
        case TryOnAvatarLoadFailed():
          TopNotification.show(context, message: '無法載入照片，請重新試穿');
        case TryOnRateLimited(:final isVideo):
          UpgradeDialog.show(
            context,
            title: isVideo ? '影片試穿次數已達上限' : '試穿次數已達上限',
            content: isVideo
                ? '您的今日影片試穿次數已達上限\n升級至更高方案以獲得更多影片次數！'
                : '您的今日試穿次數已達上限\n升級至更高方案以獲得更多次數！',
          );
        case TryOnFailed(:final failure):
          TopNotification.show(context, message: failure.displayMessage(context));
      }
    }

    Future<void> tryOnFromLocal() async {
      final File? clothesImage = await ImagePickerHelper.pickImage(
        context,
        title: '選擇服飾來源',
        hint: '建議上傳乾淨背景、單件服飾的清晰照片。',
      );
      if (clothesImage == null) return;

      final outcome = await ref
          .read(homeControllerProvider.notifier)
          .tryOnFromLocalImage(clothesImage);
      handleTryOnOutcome(outcome);
    }

    Future<void> tryOnFromStorage(
      final List<String> clothesPaths, {
      final TryOnMode mode = TryOnMode.image,
    }) async {
      final outcome = await ref
          .read(homeControllerProvider.notifier)
          .tryOnFromStoragePaths(clothesPaths, mode: mode);
      handleTryOnOutcome(outcome);
    }

    Future<void> downloadCurrentMedia() async {
      final result = galleryState.currentResult;
      if (result == null) return;

      final outcome = await ref.read(saveTryonMediaUseCaseProvider)(result);
      if (!context.mounted) return;
      if (outcome.isFailure) {
        TopNotification.show(context, message: '儲存失敗，請檢查儲存權限');
      } else {
        AppSnackBar.show(
          context,
          message: result.mode == TryOnMode.video ? '影片已儲存到相簿' : '照片已儲存到相簿',
        );
      }
    }

    Future<void> shareCurrentMedia() async {
      final result = galleryState.currentResult;
      if (result == null) return;

      final outcome = await ref.read(shareTryonMediaUseCaseProvider)(result);
      if (!context.mounted) return;
      if (outcome.isFailure) {
        TopNotification.show(context, message: '分享失敗，請稍後再試');
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
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset(AppConstants.logoMark, height: 28, fit: BoxFit.contain),
                  const SizedBox(width: AppSpacing.xs),
                  Image.asset(
                    AppConstants.logoWordmarkText,
                    height: 28,
                    fit: BoxFit.contain,
                  ),
                ],
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
                                  icon: Icons.ios_share_rounded,
                                  title: '分享',
                                  subtitle: '分享試穿照片',
                                  onTap: shareCurrentMedia,
                                ),
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
                    icon: hasAvatar
                        ? Image.asset(
                            AppConstants.logoMark,
                            width: 20,
                            height: 20,
                            fit: BoxFit.contain,
                          )
                        : Icon(
                            Icons.upload_rounded,
                            size: 20,
                            color: Theme.of(context).colorScheme.primaryContainer,
                          ),
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
