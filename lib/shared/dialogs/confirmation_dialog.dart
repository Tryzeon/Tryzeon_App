import 'package:flutter/material.dart';

class ConfirmationDialog extends StatelessWidget {
  const ConfirmationDialog({
    super.key,
    this.title,
    required this.content,
    this.cancelText = '取消',
    this.confirmText = '確定',
  });
  final String? title;
  final String content;
  final String cancelText;
  final String confirmText;

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.8, end: 1.0),
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        builder: (final context, final scale, final child) {
          return Transform.scale(scale: scale, child: child);
        },
        child: Container(
          width: MediaQuery.of(context).size.width * 0.85,
          constraints: const BoxConstraints(maxWidth: 360),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [colorScheme.surface, colorScheme.surface.withValues(alpha: 0.95)],
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withValues(alpha: 0.08),
                blurRadius: 32,
                offset: const Offset(0, 16),
                spreadRadius: -4,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 32),

              // 圖示
              Icon(Icons.error_outline_rounded, size: 48, color: colorScheme.primary),
              const SizedBox(height: 12),

              // 標題
              if (title != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    title!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                      letterSpacing: -0.5,
                      height: 1.2,
                    ),
                  ),
                ),
              if (title != null) const SizedBox(height: 12),

              // 說明文字
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  content,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: colorScheme.onSurface.withValues(alpha: 0.65),
                    height: 1.5,
                    letterSpacing: 0.1,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // 按鈕
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: Row(
                  children: [
                    if (cancelText.isNotEmpty) ...[
                      Expanded(
                        child: SizedBox(
                          height: 52,
                          child: TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            style: TextButton.styleFrom(
                              foregroundColor: colorScheme.onSurface.withValues(
                                alpha: 0.7,
                              ),
                              backgroundColor: colorScheme.surfaceContainerHighest
                                  .withValues(alpha: 0.3),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Text(
                              cancelText,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shadowColor: colorScheme.primary.withValues(alpha: 0.4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            confirmText,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 顯示確認對話框
  static Future<bool?> show({
    required final BuildContext context,
    final String? title,
    required final String content,
    final String cancelText = '取消',
    final String confirmText = '確定',
  }) {
    return showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (final context) => ConfirmationDialog(
        title: title,
        content: content,
        cancelText: cancelText,
        confirmText: confirmText,
      ),
    );
  }
}
