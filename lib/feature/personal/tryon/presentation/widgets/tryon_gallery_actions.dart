import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/presentation/widgets/app_action_sheet.dart';
import 'package:tryzeon/core/presentation/widgets/app_confirm_dialog.dart';
import 'package:tryzeon/core/presentation/widgets/app_snack_bar.dart';
import 'package:tryzeon/core/presentation/widgets/top_notification.dart';
import 'package:tryzeon/feature/personal/subscription/providers/subscription_capabilities_provider.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_mode.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/controllers/tryon_controller.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/state/tryon_gallery_provider.dart';
import 'package:tryzeon/feature/personal/tryon/providers/tryon_providers.dart';

/// The action button floating over the gallery. Replacing the model photo is
/// offered on every page; a finished try-on adds share / download / animate /
/// set-as-avatar / delete on top, and one still generating offers to cancel.
///
/// Owns its own handlers so the home page stays a layout — the only action it
/// cannot own is [onReplaceAvatar], which the home CTA offers as well.
class TryonGalleryActions extends ConsumerWidget {
  const TryonGalleryActions({super.key, required this.onReplaceAvatar});

  final VoidCallback onReplaceAvatar;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final gallery = ref.watch(tryonGalleryProvider);
    final result = gallery.currentResult;
    final isCurrentTheAvatar = gallery.isCurrentTheAvatar;

    Future<void> shareMedia() async {
      if (result == null) return;

      final outcome = await ref.read(shareTryonMediaUseCaseProvider)(result);
      if (!context.mounted) return;
      if (outcome.isFailure) {
        TopNotification.show(context, message: '分享失敗，請稍後再試');
      }
    }

    Future<void> downloadMedia() async {
      if (result == null) return;

      final outcome = await ref.read(saveTryonMediaUseCaseProvider)(result);
      if (!context.mounted) return;
      if (outcome.isFailure) {
        TopNotification.show(context, message: '儲存失敗，請檢查儲存權限');
      } else {
        AppSnackBar.show(
          context,
          message: result.mode == TryonMode.video ? '影片已儲存到相簿' : '照片已儲存到相簿',
        );
      }
    }

    // `!= false` so a still-loading capability keeps the action visible: a slow
    // cache must not hide a feature the user has paid for. The backend rejects
    // the request anyway if the entitlement turns out to be missing.
    final hasVideoAccess = ref.watch(
      subscriptionCapabilitiesProvider.select(
        (final async) => async.value?.hasVideoAccess != false,
      ),
    );

    Future<void> animateToVideo() async {
      if (result == null) return;

      await ref.read(tryonControllerProvider.notifier).animate(result);
    }

    final targetId = gallery.currentId;

    Future<void> confirmCancelGeneration() async {
      if (targetId == null) return;

      final choice = await showAppOkCancelDialog(
        context: context,
        message: '確定要取消這次試穿嗎？',
        okLabel: '取消生成',
        cancelLabel: '繼續等待',
        isDestructiveAction: true,
      );

      // Dropping the placeholder is the cancel: the controller sees it gone and
      // lets the in-flight response land silently.
      if (choice == OkCancelResult.ok) {
        ref.read(tryonGalleryProvider.notifier).removeById(targetId);
      }
    }

    Future<void> confirmDelete() async {
      if (targetId == null) return;

      final choice = await showAppOkCancelDialog(
        context: context,
        message: '確定要刪除這張試穿照片嗎？',
        okLabel: '刪除',
        cancelLabel: '取消',
        isDestructiveAction: true,
      );

      if (choice == OkCancelResult.ok) {
        ref.read(tryonGalleryProvider.notifier).removeById(targetId);
      }
    }

    final replaceAvatar = AppMenuAction(
      icon: Icons.swap_horiz_rounded,
      title: '更換模特圖片',
      subtitle: '上傳照片更換試穿模特',
      onTap: onReplaceAvatar,
    );

    final actions = switch (gallery) {
      TryonGalleryState(isAvatarPage: true) => [replaceAvatar],
      TryonGalleryState(isCurrentPending: true) => [
        replaceAvatar,
        AppMenuAction(
          icon: Icons.stop_circle_outlined,
          title: '取消生成',
          subtitle: '停止等待這次試穿結果',
          onTap: confirmCancelGeneration,
          isDestructive: true,
        ),
      ],
      _ => [
        AppMenuAction(
          icon: Icons.ios_share_rounded,
          title: '分享',
          subtitle: '分享試穿照片',
          onTap: shareMedia,
        ),
        AppMenuAction(
          icon: Icons.download_rounded,
          title: '下載',
          subtitle: '儲存到相簿',
          onTap: downloadMedia,
        ),
        if (result?.mode == TryonMode.image && hasVideoAccess)
          AppMenuAction(
            icon: Icons.movie_creation_outlined,
            title: '轉成影片',
            subtitle: '讓這張試穿動起來',
            onTap: animateToVideo,
          ),
        if (result?.mode == TryonMode.image)
          AppMenuAction(
            icon: isCurrentTheAvatar
                ? Icons.person_off_outlined
                : Icons.person_outline_rounded,
            title: isCurrentTheAvatar ? '取消我的形象' : '設為我的形象',
            subtitle: isCurrentTheAvatar ? '取消使用此照片作為試穿形象' : '使用此照片作為試穿形象',
            onTap: ref.read(tryonGalleryProvider.notifier).toggleAvatarForCurrent,
          ),
        replaceAvatar,
        AppMenuAction(
          icon: Icons.delete_outline_rounded,
          title: '刪除此試穿',
          subtitle: '移除這張試穿照片',
          onTap: confirmDelete,
          isDestructive: true,
        ),
      ],
    };

    return IconButton(
      icon: Icon(Icons.more_vert_rounded, color: Theme.of(context).colorScheme.onPrimary),
      onPressed: () => showAppActionSheet(context, actions: actions),
    );
  }
}
