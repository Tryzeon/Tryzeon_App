import 'package:flutter/material.dart';

enum NotificationType {
  success,
  error,
  info,
  warning,
}

class TopNotification {
  static void show(
    BuildContext context, {
    required String message,
    NotificationType type = NotificationType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => _TopNotificationWidget(
        message: message,
        type: type,
        onDismiss: () => overlayEntry.remove(),
      ),
    );

    overlay.insert(overlayEntry);

    // 自動移除
    Future.delayed(duration, () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }
}

class _TopNotificationWidget extends StatefulWidget {
  final String message;
  final NotificationType type;
  final VoidCallback onDismiss;

  const _TopNotificationWidget({
    required this.message,
    required this.type,
    required this.onDismiss,
  });

  @override
  State<_TopNotificationWidget> createState() => _TopNotificationWidgetState();
}

class _TopNotificationWidgetState extends State<_TopNotificationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _dismiss() async {
    await _controller.reverse();
    widget.onDismiss();
  }

  Color _getBackgroundColor(BuildContext context) {
    switch (widget.type) {
      case NotificationType.success:
        return const Color(0xFF10B981);
      case NotificationType.error:
        return const Color(0xFFEF4444);
      case NotificationType.warning:
        return const Color(0xFFF59E0B);
      case NotificationType.info:
        return const Color(0xFF3B82F6);
    }
  }

  IconData _getIcon() {
    switch (widget.type) {
      case NotificationType.success:
        return Icons.check_circle;
      case NotificationType.error:
        return Icons.cancel;
      case NotificationType.warning:
        return Icons.warning;
      case NotificationType.info:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: GestureDetector(
                onVerticalDragEnd: (details) {
                  if (details.primaryVelocity != null && details.primaryVelocity! < 0) {
                    _dismiss();
                  }
                },
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
                            // 左側彩色條
                            Container(
                              width: 4,
                              color: _getBackgroundColor(context),
                            ),
                            // 內容區域
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                child: Row(
                                  children: [
                                    Icon(
                                      _getIcon(),
                                      color: _getBackgroundColor(context),
                                      size: 24,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        widget.message,
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
                                      onTap: _dismiss,
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
    );
  }
}
