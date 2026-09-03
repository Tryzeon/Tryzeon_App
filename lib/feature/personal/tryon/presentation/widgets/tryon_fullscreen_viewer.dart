import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:photo_view/photo_view.dart';
import 'package:tryzeon/core/theme/app_theme.dart';

/// An [Overlay] layer rather than a pushed route: the page underneath is never
/// torn down, so opening and closing only fade. The same `cover` framing as the
/// gallery means opening introduces no zoom.
abstract final class TryonFullscreenViewer {
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

    useEffect(() {
      controller.forward();
      return null;
    }, const []);

    Future<void> close() async {
      if (isClosing.value) return;
      isClosing.value = true;
      await controller.reverse();
      onClosed();
    }

    return Material(
      type: MaterialType.transparency,
      child: FadeTransition(
        opacity: controller,
        child: Stack(
          children: [
            Positioned.fill(
              child: PhotoView(
                imageProvider: imageProvider,
                backgroundDecoration: BoxDecoration(color: colorScheme.scrim),
                initialScale: PhotoViewComputedScale.covered,
                minScale: PhotoViewComputedScale.covered,
                maxScale: PhotoViewComputedScale.covered * 3,
                onTapUp: (final context, final details, final controllerValue) => close(),
                loadingBuilder: (final context, final event) =>
                    const Center(child: CircularProgressIndicator()),
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
                onPressed: close,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
