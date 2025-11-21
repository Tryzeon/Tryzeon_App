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
  }) {
    final duration = type == NotificationType.error
        ? const Duration(seconds: 10)
        : const Duration(seconds: 3);

    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;
    final GlobalKey<_TopNotificationWidgetState> key = GlobalKey();

    overlayEntry = OverlayEntry(
      builder: (context) => _TopNotificationWidget(
        key: key,
        message: message,
        type: type,
        onDismiss: () => overlayEntry.remove(),
      ),
    );

    overlay.insert(overlayEntry);

    // 自動移除
    Future.delayed(duration, () async {
      if (overlayEntry.mounted && key.currentState != null) {
        await key.currentState!._dismiss();
      }
    });
  }
}

class _TopNotificationWidget extends StatefulWidget {
  final String message;
  final NotificationType type;
  final VoidCallback onDismiss;

  const _TopNotificationWidget({
    super.key,
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
  double _dragOffset = 0.0;

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

  Future<void> _dismiss() async {
    await _controller.reverse();
    widget.onDismiss();
  }

  (Color, IconData) _getStyle() {
    return switch (widget.type) {
      NotificationType.success => (const Color(0xFF10B981), Icons.check_circle),
      NotificationType.error => (const Color(0xFFEF4444), Icons.cancel),
      NotificationType.warning => (const Color(0xFFF59E0B), Icons.warning),
      NotificationType.info => (const Color(0xFF3B82F6), Icons.info),
    };
  }

  @override
  Widget build(BuildContext context) {
    final (color, icon) = _getStyle();

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SafeArea(
            child: Transform.translate(
              offset: Offset(0, _dragOffset),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: GestureDetector(
                  onVerticalDragUpdate: (details) {
                    setState(() {
                      _dragOffset += details.delta.dy;
                      if (_dragOffset > 0) _dragOffset = 0;
                    });
                  },
                  onVerticalDragEnd: (details) {
                    if (_dragOffset < -50 || (details.primaryVelocity != null && details.primaryVelocity! < -300)) {
                      _dismiss();
                    } else {
                      setState(() => _dragOffset = 0);
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
      ),
    );
  }
}
