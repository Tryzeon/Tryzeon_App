import 'package:flutter/material.dart';
import 'package:tryzeon/core/theme/app_theme.dart';

class ChatInputBar extends StatelessWidget {
  const ChatInputBar({
    super.key,
    required this.controller,
    required this.enabled,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool enabled;
  final VoidCallback onSend;

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      color: theme.colorScheme.surface,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              constraints: const BoxConstraints(minHeight: AppSpacing.xxl),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainer,
                borderRadius: AppRadius.pillAll,
              ),
              child: TextField(
                controller: controller,
                maxLines: 1,
                textInputAction: TextInputAction.send,
                keyboardType: TextInputType.text,
                onSubmitted: enabled ? (_) => onSend() : null,
                style: theme.textTheme.bodyLarge,
                decoration: const InputDecoration(
                  hintText: '請輸入您的回答...',
                  isDense: true,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          SizedBox(
            width: AppSpacing.xxl,
            height: AppSpacing.xxl,
            child: ListenableBuilder(
              listenable: controller,
              builder: (final context, final _) {
                final hasText = controller.text.trim().isNotEmpty;
                return IconButton.filled(
                  icon: const Icon(Icons.send_rounded, size: AppSpacing.lg),
                  onPressed: (enabled && hasText) ? onSend : null,
                  style: IconButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    disabledBackgroundColor: theme.colorScheme.surfaceContainerHighest,
                    disabledForegroundColor: theme.colorScheme.onSurfaceVariant,
                    shape: const CircleBorder(),
                    padding: EdgeInsets.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    animationDuration: Duration.zero,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
