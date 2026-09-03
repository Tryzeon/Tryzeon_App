import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:tryzeon/core/config/app_constants.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/personal/tryon/domain/entities/tryon_mode.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/state/tryon_gallery_entry.dart';
import 'package:tryzeon/feature/personal/tryon/presentation/widgets/tryon_fullscreen_viewer.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

class TryonGallery extends HookWidget {
  const TryonGallery({
    super.key,
    required this.pageController,
    required this.onPageChanged,
    required this.entries,
    required this.avatarFile,
    required this.isAvatarBusy,
    required this.onReplaceAvatar,
  });

  final PageController pageController;
  final ValueChanged<int> onPageChanged;
  final List<TryonGalleryEntry> entries;
  final File? avatarFile;

  final bool isAvatarBusy;

  final VoidCallback onReplaceAvatar;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          controller: pageController,
          onPageChanged: onPageChanged,
          itemCount: entries.length + 1,
          itemBuilder: (final context, final index) {
            if (index == 0) {
              // Original Avatar
              final ImageProvider imageProvider = avatarFile != null
                  ? FileImage(avatarFile!)
                  : const AssetImage(AppConstants.defaultProfileImage);
              return GestureDetector(
                onTap: onReplaceAvatar,
                child: _AvatarImageItem(
                  imageProvider: imageProvider,
                  isBusy: isAvatarBusy,
                ),
              );
            }

            switch (entries[index - 1]) {
              case PendingTryonEntry():
                return const _LoadingAnimationItem();
              case FinishedTryonEntry(:final result):
                if (result.mode == TryonMode.video) {
                  final videoUrl = result.videoUrl;
                  if (videoUrl == null || videoUrl.isEmpty) {
                    return const Center(child: Text('Video unavailable'));
                  }
                  return _TryonVideoItem(videoUrl: videoUrl);
                }

                final imageUrl = result.imageUrl;
                if (imageUrl == null || imageUrl.isEmpty) {
                  return const Center(child: Text('Image unavailable'));
                }
                return GestureDetector(
                  onTap: () => TryonFullscreenViewer.open(
                    context,
                    imageProvider: CachedNetworkImageProvider(imageUrl),
                  ),
                  child: _TryonImageItem(imageUrl: imageUrl),
                );
            }
          },
        ),
        // Top Dark Gradient — ensures white logo/icons are legible
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          height: 200,
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    colorScheme.scrim.withValues(alpha: AppOpacity.strong),
                    colorScheme.scrim.withValues(alpha: 0),
                  ],
                  stops: const [0.0, 1.0],
                ),
              ),
            ),
          ),
        ),
        // Bottom Dark Gradient — ensures white indicator/button are legible
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 250,
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    colorScheme.scrim.withValues(alpha: AppOpacity.strong),
                    colorScheme.scrim.withValues(alpha: 0),
                  ],
                  stops: const [0.0, 1.0],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LoadingAnimationItem extends HookWidget {
  const _LoadingAnimationItem();

  static List<String>? _sessionOrder;
  static int _nextIndex = 0;

  @override
  Widget build(final BuildContext context) {
    useAutomaticKeepAlive();

    final colorScheme = Theme.of(context).colorScheme;
    final controller = useMemoized(() {
      final order = _sessionOrder ??= (AppConstants.tryonLoadingAnimations.toList()
        ..shuffle());
      final asset = order[_nextIndex];
      _nextIndex = (_nextIndex + 1) % order.length;
      return VideoPlayerController.asset(asset);
    });
    final isInitialized = useState(false);

    useEffect(() {
      controller.initialize().then((_) {
        controller.setLooping(true);
        controller.setVolume(0);
        controller.play();
        isInitialized.value = true;
      });
      return controller.dispose;
    }, [controller]);

    return ColoredBox(
      color: colorScheme.surface,
      child: isInitialized.value ? _coverVideoFill(controller) : const SizedBox.expand(),
    );
  }
}

class _AvatarImageItem extends HookWidget {
  const _AvatarImageItem({required this.imageProvider, required this.isBusy});

  final ImageProvider imageProvider;
  final bool isBusy;

  @override
  Widget build(final BuildContext context) {
    useAutomaticKeepAlive();

    final colorScheme = Theme.of(context).colorScheme;

    return Stack(
      fit: StackFit.expand,
      children: [
        Image(image: imageProvider, fit: BoxFit.cover, gaplessPlayback: true),
        if (isBusy)
          ColoredBox(
            color: colorScheme.scrim.withValues(alpha: AppOpacity.overlay),
            child: Center(
              child: SizedBox(
                width: 44,
                height: 44,
                child: CircularProgressIndicator(
                  strokeWidth: AppStroke.medium,
                  color: colorScheme.onPrimary,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _TryonImageItem extends HookWidget {
  const _TryonImageItem({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(final BuildContext context) {
    useAutomaticKeepAlive();

    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      fadeInDuration: Duration.zero,
      fadeOutDuration: Duration.zero,
      placeholder: (final context, final url) =>
          const Center(child: CircularProgressIndicator()),
      // The cache streams bytes to disk and keeps no copy, so a failed write
      // (full device) discards an image that downloaded fine.
      errorWidget: (final context, final url, final error) => Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (final context, final error, final stackTrace) =>
            const Center(child: Icon(Icons.broken_image_outlined)),
      ),
    );
  }
}

Widget _coverVideoFill(final VideoPlayerController controller) {
  return LayoutBuilder(
    builder: (final context, final constraints) {
      final screenHeight = constraints.maxHeight;
      final scaledWidth = screenHeight * controller.value.aspectRatio;
      return ClipRect(
        child: OverflowBox(
          maxWidth: double.infinity,
          maxHeight: screenHeight,
          child: SizedBox(
            width: scaledWidth,
            height: screenHeight,
            child: VideoPlayer(controller),
          ),
        ),
      );
    },
  );
}

class _TryonVideoItem extends HookWidget {
  const _TryonVideoItem({required this.videoUrl});
  final String videoUrl;

  @override
  Widget build(final BuildContext context) {
    useAutomaticKeepAlive();

    final colorScheme = Theme.of(context).colorScheme;
    final controller = useMemoized(
      () => VideoPlayerController.networkUrl(Uri.parse(videoUrl)),
      [videoUrl],
    );
    final isInitialized = useState(false);
    final visibleFraction = useState(1.0);
    final isPaused = useState(false);

    useEffect(() {
      controller.initialize().then((_) {
        isInitialized.value = true;
        controller.setLooping(true);
      });
      return controller.dispose;
    }, [controller]);

    useEffect(() {
      if (!isInitialized.value) return null;
      final shouldPlay = !isPaused.value && visibleFraction.value > 0.5;
      if (shouldPlay && !controller.value.isPlaying) {
        controller.play();
      } else if (!shouldPlay && controller.value.isPlaying) {
        controller.pause();
      }
      return null;
    }, [isInitialized.value, visibleFraction.value, isPaused.value]);

    return VisibilityDetector(
      key: ValueKey('video-$videoUrl'),
      onVisibilityChanged: (final info) {
        if (!context.mounted) return;
        visibleFraction.value = info.visibleFraction;
      },
      child: !isInitialized.value
          ? ColoredBox(
              color: colorScheme.surfaceContainerLow,
              child: Center(
                child: CircularProgressIndicator(color: colorScheme.onSurface),
              ),
            )
          : GestureDetector(
              onTap: () => isPaused.value = controller.value.isPlaying,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  _coverVideoFill(controller),
                  if (isPaused.value)
                    Icon(
                      Icons.play_arrow_rounded,
                      color: colorScheme.onPrimary.withValues(alpha: AppOpacity.overlay),
                      size: 64,
                    ),
                ],
              ),
            ),
    );
  }
}
