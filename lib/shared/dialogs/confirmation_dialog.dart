import 'package:flutter/material.dart';

class ConfirmationDialog extends StatelessWidget {
  final String? title;
  final String content;
  final String cancelText;
  final String confirmText;

  const ConfirmationDialog({
    super.key,
    this.title,
    required this.content,
    this.cancelText = '取消',
    this.confirmText = '確定',
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      contentPadding: const EdgeInsets.fromLTRB(24, 30, 24, 25),
      title: title != null
          ? Text(
              title!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            )
          : null,
      content: Text(
        content,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontSize: 16,
        ),
      ),
      actions: [
        if (cancelText.isNotEmpty)
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              cancelText,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(confirmText),
        ),
      ],
    );
  }

  /// 顯示確認對話框
  static Future<bool?> show({
    required BuildContext context,
    String? title,
    required String content,
    String cancelText = '取消',
    String confirmText = '確定',
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: title,
        content: content,
        cancelText: cancelText,
        confirmText: confirmText,
      ),
    );
  }
}
