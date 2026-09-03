import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:tryzeon/core/presentation/widgets/top_notification.dart';
import 'package:tryzeon/core/theme/app_theme.dart';

class WardrobeTagEditorSheet extends HookWidget {
  const WardrobeTagEditorSheet({
    super.key,
    required this.initialTags,
    required this.onSave,
  });

  final List<String> initialTags;
  final Future<String?> Function(List<String> tags) onSave;

  static Future<bool?> show({
    required final BuildContext context,
    required final List<String> initialTags,
    required final Future<String?> Function(List<String> tags) onSave,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (final context) {
        return WardrobeTagEditorSheet(initialTags: initialTags, onSave: onSave);
      },
    );
  }

  @override
  Widget build(final BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final tags = useState<List<String>>(List<String>.of(initialTags));
    final controller = useTextEditingController();
    final isSaving = useState(false);

    void addTag() {
      final text = controller.text.trim();
      if (text.isEmpty) return;
      if (!tags.value.contains(text)) {
        tags.value = [...tags.value, text];
      }
      controller.clear();
    }

    void removeTag(final int index) {
      final nextTags = List<String>.of(tags.value)..removeAt(index);
      tags.value = nextTags;
    }

    Future<void> handleSave() async {
      isSaving.value = true;

      final pendingTag = controller.text.trim();
      if (pendingTag.isNotEmpty) {
        addTag();
      }

      final errorMessage = await onSave(tags.value);
      if (!context.mounted) return;

      isSaving.value = false;
      if (errorMessage == null) {
        Navigator.pop(context, true);
        return;
      }

      TopNotification.show(context, message: errorMessage);
    }

    Widget buildTagList() {
      if (tags.value.isEmpty) {
        return Text(
          '尚無標籤',
          style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
        );
      }

      return Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          for (final entry in tags.value.asMap().entries)
            Chip(
              label: Text('#${entry.value}'.toUpperCase()),
              onDeleted: () => removeTag(entry.key),
            ),
        ],
      );
    }

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Area
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('編輯標籤', style: textTheme.titleMedium),
                TextButton(
                  onPressed: isSaving.value ? null : handleSave,
                  child: isSaving.value
                      ? const SizedBox(
                          width: AppSpacing.md,
                          height: AppSpacing.md,
                          child: CircularProgressIndicator(
                            strokeWidth: AppStroke.regular,
                          ),
                        )
                      : const Text('完成'),
                ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                MediaQuery.of(context).padding.bottom + AppSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: controller,
                    textInputAction: TextInputAction.done,
                    style: textTheme.bodyLarge,
                    decoration: InputDecoration(
                      hintText: '新增標籤...',
                      suffixIcon: GestureDetector(
                        onTap: addTag,
                        behavior: HitTestBehavior.opaque,
                        child: Icon(
                          Icons.add_rounded,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    onSubmitted: (final _) => addTag(),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  buildTagList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
