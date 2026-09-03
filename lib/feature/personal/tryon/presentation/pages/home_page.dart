import 'dart:io';

import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/config/app_constants.dart';
import 'package:tryzeon/core/extensions/failure_extension.dart';
import 'package:tryzeon/core/presentation/dialogs/upgrade_dialog.dart';
import 'package:tryzeon/core/presentation/widgets/error_view.dart';
import 'package:tryzeon/core/presentation/widgets/top_notification.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/core/utils/crop_options.dart';
import 'package:tryzeon/core/utils/image_picker_helper.dart';
import 'package:tryzeon/feature/personal/profile/providers/personal_profile_providers.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_mode.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/controllers/tryon_controller.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/coordinators/tryon_coordinator.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/sheets/tryon_mode_sheet.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/state/tryon_gallery_provider.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/state/tryon_outcome.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/widgets/home_primary_action_button.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/widgets/tryon_avatar_badge.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/widgets/tryon_disclaimer.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/widgets/tryon_gallery.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/widgets/tryon_gallery_actions.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/widgets/tryon_indicator.dart';
import 'package:typed_result/typed_result.dart';

class HomePage extends HookConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final avatarAsync = ref.watch(avatarFileProvider);
    // Only surface an error once it settles with no photo to fall back on.
    final avatarError = avatarAsync.isLoading || avatarAsync.hasValue
        ? null
        : avatarAsync.error;
    final hasAvatar =
        ref.watch(userProfileProvider).value?.avatarPath?.isNotEmpty ?? false;
    final galleryState = ref.watch(tryonGalleryProvider);
    final galleryNotifier = ref.read(tryonGalleryProvider.notifier);
    final isUploadingAvatar = ref.watch(avatarUploadProvider).isLoading;
    final pageController = usePageController(initialPage: 0);

    final colorScheme = Theme.of(context).colorScheme;

    final currentPage = galleryState.currentPage;
    final isCurrentTheAvatar = galleryState.isCurrentTheAvatar;

    useEffect(() {
      if (pageController.hasClients && pageController.page?.round() != currentPage) {
        pageController.animateToPage(
          currentPage,
          duration: AppDuration.slow,
          curve: AppCurves.standard,
        );
      }
      return null;
    }, [currentPage]);

    Future<void> uploadAvatar() async {
      final File? imageFile = await ImagePickerHelper.pickImage(
        context,
        title: '選擇模特來源',
        hint: '建議上傳短袖短褲的正面全身照，雙手自然下垂、手上不要拿手機等物品。',
        crop: const LockedCrop(ratio: AppConstants.avatarAspectRatio, title: '框出全身'),
      );
      if (imageFile == null) return;

      final result = await ref.read(avatarUploadProvider.notifier).upload(imageFile);
      if (!context.mounted) return;
      if (result.isFailure) {
        TopNotification.show(
          context,
          message: result.getError()!.displayMessage(context),
        );
        return;
      }
      galleryNotifier.showAvatarPage();
    }

    void handleTryonOutcome(final TryonOutcome outcome) {
      if (!context.mounted) return;
      switch (outcome) {
        case TryonSucceeded():
          HapticFeedback.heavyImpact();
        case TryonAvatarMissing():
          TopNotification.show(context, message: '請先上傳個人照片才能開始試穿呦！');
        case TryonRateLimited(:final isVideo):
          UpgradeDialog.show(
            context,
            title: isVideo ? '影片試穿次數已達上限' : '試穿次數已達上限',
            content: isVideo
                ? '您的今日影片試穿次數已達上限\n升級至更高方案以獲得更多影片次數！'
                : '您的今日試穿次數已達上限\n升級至更高方案以獲得更多次數！',
          );
        case TryonFailed(:final failure):
          TopNotification.show(context, message: failure.displayMessage(context));
      }
    }

    ref.listen(tryonControllerProvider, (final _, final outcome) {
      if (outcome != null) handleTryonOutcome(outcome);
    });

    Future<void> tryonFromLocal(final TryonMode mode) async {
      final File? garmentImage = await ImagePickerHelper.pickImage(
        context,
        title: '選擇服飾來源',
        hint: '建議上傳乾淨背景、單件服飾的清晰照片。',
      );
      if (garmentImage == null) return;

      await ref
          .read(tryonCoordinatorProvider)
          .tryonFromLocalImage(garmentImage, mode: mode);
    }

    void startTryon() {
      HapticFeedback.mediumImpact();
      TryonModeSheet.show(context: context, onModeSelected: tryonFromLocal);
    }

    final bottomOffset =
        MediaQuery.paddingOf(context).bottom +
        (PlatformInfo.isIOS26OrHigher() ? AppSpacing.iosTabBarHeight : 0);

    final isAvatarPage = galleryState.isAvatarPage;

    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      body: RefreshIndicator(
        onRefresh: () => ref.read(userProfileProvider.notifier).refresh(),
        edgeOffset: MediaQuery.of(context).padding.top,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Background Image Layer — wrapped in scrollable for RefreshIndicator
            SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.of(context).size.height,
                child: avatarError != null
                    ? Center(
                        child: ErrorView(
                          message: avatarError.displayMessage(context),
                          onRetry: () => ref.invalidate(userProfileProvider),
                        ),
                      )
                    : TryonGallery(
                        pageController: pageController,
                        onPageChanged: galleryNotifier.setCurrentPage,
                        entries: galleryState.entries,
                        avatarFile: avatarAsync.value,
                        isAvatarBusy: avatarAsync.isLoading || isUploadingAvatar,
                        onReplaceAvatar: uploadAvatar,
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

            // 3. Top Right — Avatar Badge + More Options (parallel). Always up:
            // the sheet adapts its actions to the page in view.
            Positioned(
              top: MediaQuery.paddingOf(context).top + AppSpacing.xs,
              right: AppSpacing.md,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  TryonAvatarBadge(isVisible: isCurrentTheAvatar),
                  const SizedBox(width: AppSpacing.sm),
                  TryonGalleryActions(onReplaceAvatar: uploadAvatar),
                ],
              ),
            ),

            // 4. Bottom Left — Indicator (white floating lines) with the AI
            // disclaimer as the last element on the page, so it reads as a
            // footnote rather than a caption for the indicator. The group hangs
            // from a lower anchor to leave the indicator where it was.
            if (!isAvatarPage)
              Positioned(
                bottom: bottomOffset + AppSpacing.smMd,
                left: AppSpacing.xxl,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TryonIndicator(
                      currentTryonIndex: galleryState.currentIndex,
                      tryonImagesCount: galleryState.entries.length,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    const TryonDisclaimer(),
                  ],
                ),
              ),

            // 5. Bottom Right — Try On Button (dark glassmorphism pill).
            // Only an in-flight avatar upload blocks it: the backend resolves
            // the model photo itself, so a try-on never waits on the download.
            Positioned(
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
                        color: colorScheme.primaryContainer,
                      ),
                isDisabled: isUploadingAvatar,
                onTap: hasAvatar ? startTryon : uploadAvatar,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
