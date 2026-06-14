import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:photo_view/photo_view.dart';
import 'package:tryzeon/core/theme/app_theme.dart';

/// Full-screen, zoomable image viewer shown as an [Overlay] layer on top of the
/// current page (not a pushed route).
///
/// Opening scales the layer up from the gallery's `cover` framing into
/// `contain`; the close button reverses it; a vertical swipe removes the layer
/// instantly (the page underneath is never torn down, so there is no flicker).
abstract final class TryOnFullscreenViewer {
  /// Inserts the viewer as a layer above everything via the root [Overlay].
  static void open(
    final BuildContext context, {
    required final ImageProvider imageProvider,
  }) {
    final overlay = Overlay.of(context, rootOverlay: true);
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (final context) =>
          _ViewerLayer(imageProvider: imageProvider, onClosed: entry.remove),
    );
    overlay.insert(entry);
  }
}

class _ViewerLayer extends HookWidget {
  const _ViewerLayer({required this.imageProvider, required this.onClosed});

  final ImageProvider imageProvider;
  final VoidCallback onClosed;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final controller = useAnimationController(duration: AppDuration.standard);
    final isClosing = useRef(false);
    final imageSize = useState<Size?>(null);

    // Resolve the image's intrinsic size so the open animation can start from
    // the gallery's `cover` framing and settle into `contain`.
    useEffect(() {
      final stream = imageProvider.resolve(const ImageConfiguration());
      final listener = ImageStreamListener((final info, final _) {
        imageSize.value = Size(info.image.width.toDouble(), info.image.height.toDouble());
      });
      stream.addListener(listener);
      return () => stream.removeListener(listener);
    }, [imageProvider]);

    useEffect(() {
      controller.forward();
      return null;
    }, const []);

    Future<void> close({required final bool animated}) async {
      if (isClosing.value) return;
      isClosing.value = true;
      if (animated) {
        await controller.reverse();
      }
      onClosed();
    }

    // Scale factor that makes a `contain`-fitted image match the gallery's
    // `cover` framing; 1.0 (no extra scale) until the size is known.
    final size = imageSize.value;
    double coverScale = 1;
    if (size != null) {
      final screen = MediaQuery.sizeOf(context);
      final contain = math.min(screen.width / size.width, screen.height / size.height);
      final cover = math.max(screen.width / size.width, screen.height / size.height);
      if (contain > 0) coverScale = cover / contain;
    }

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          Positioned.fill(
            child: Dismissible(
              key: const Key('tryon-fullscreen-viewer'),
              direction: DismissDirection.vertical,
              onDismissed: (final _) => close(animated: false),
              child: ClipRect(
                child: AnimatedBuilder(
                  animation: controller,
                  builder: (final context, final child) => Transform.scale(
                    scale: lerpDouble(coverScale, 1, controller.value),
                    child: child,
                  ),
                  child: PhotoView(
                    imageProvider: imageProvider,
                    backgroundDecoration: BoxDecoration(color: colorScheme.scrim),
                    minScale: PhotoViewComputedScale.contained,
                    maxScale: PhotoViewComputedScale.covered * 3,
                    loadingBuilder: (final context, final event) =>
                        const Center(child: CircularProgressIndicator()),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.paddingOf(context).top + AppSpacing.sm,
            right: AppSpacing.sm,
            child: IconButton(
              icon: Icon(Icons.close_rounded, color: colorScheme.onInverseSurface),
              splashColor: colorScheme.onInverseSurface.withValues(
                alpha: AppOpacity.medium,
              ),
              onPressed: () => close(animated: true),
            ),
          ),
        ],
      ),
    );
  }
}
