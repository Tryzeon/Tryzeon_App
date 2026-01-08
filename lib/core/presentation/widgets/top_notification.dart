import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

enum NotificationType { success, error, info, warning }

class TopNotification {
  static void show(
    final BuildContext context, {
    required final String message,
    final NotificationType type = NotificationType.info,
  }) {
    final duration = type == NotificationType.error
        ? const Duration(seconds: 10)
        : const Duration(seconds: 3);

    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (final context) => _TopNotificationWidget(
        message: message,
        type: type,
        onDismiss: () {
          if (overlayEntry.mounted) {
            overlayEntry.remove();
          }
        },
        autoDismissDuration: duration,
      ),
    );

    overlay.insert(overlayEntry);
  }
}

class _TopNotificationWidget extends HookConsumerWidget {
  const _TopNotificationWidget({
    required this.message,
    required this.type,
    required this.onDismiss,
    required this.autoDismissDuration,
  });
  final String message;
  final NotificationType type;
  final VoidCallback onDismiss;
  final Duration autoDismissDuration;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final controller = useAnimationController(
      duration: const Duration(milliseconds: 400),
    );

    final slideAnimation = useMemoized(
      () => Tween<Offset>(
        begin: const Offset(0, -1),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: controller, curve: Curves.easeOutCubic)),
      [controller],
    );

    final fadeAnimation = useMemoized(
      () => Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(parent: controller, curve: Curves.easeOut)),
      [controller],
    );

    final dragOffset = useState(0.0);

    // 用來觸發 dismiss 的 callback，包含反向動畫
    final dismiss = useCallback(() async {
      if (context.mounted) {
        await controller.reverse();
        onDismiss();
      }
    }, [controller, onDismiss]);

    useEffect(() {
      controller.forward();

      // 設定自動移除
      final timer = Timer(autoDismissDuration, dismiss);

      return timer.cancel;
    }, []);

    // 處理手勢
    final handleDragUpdate = useCallback((final DragUpdateDetails details) {
      dragOffset.value += details.delta.dy;
      if (dragOffset.value > 0) dragOffset.value = 0;
    }, []);

    final handleDragEnd = useCallback((final DragEndDetails details) {
      if (dragOffset.value < -50 ||
          (details.primaryVelocity != null && details.primaryVelocity! < -300)) {
        dismiss();
      } else {
        dragOffset.value = 0;
      }
    }, [dismiss]);

    final (color, icon) = _getStyle(type);

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: slideAnimation,
        child: FadeTransition(
          opacity: fadeAnimation,
          child: SafeArea(
            child: Transform.translate(
              offset: Offset(0, dragOffset.value),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: GestureDetector(
                  onVerticalDragUpdate: handleDragUpdate,
                  onVerticalDragEnd: handleDragEnd,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Material(
                        color: Colors.transparent,
                        child: IntrinsicHeight(
                          child: Row(
                            children: [
                              Container(width: 4, color: color),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      Icon(icon, color: color, size: 24),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          message,
                                          style: TextStyle(
                                            color: Colors.grey[900],
                                            fontSize: 15,
                                            fontWeight: FontWeight.w500,
                                            height: 1.4,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      GestureDetector(
                                        onTap: dismiss,
                                        child: Icon(
                                          Icons.close,
                                          color: Colors.grey[400],
                                          size: 20,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  (Color, IconData) _getStyle(final NotificationType type) {
    return switch (type) {
      NotificationType.success => (const Color(0xFF10B981), Icons.check_circle),
      NotificationType.error => (const Color(0xFFEF4444), Icons.cancel),
      NotificationType.warning => (const Color(0xFFF59E0B), Icons.warning),
      NotificationType.info => (const Color(0xFF3B82F6), Icons.info),
    };
  }
}
