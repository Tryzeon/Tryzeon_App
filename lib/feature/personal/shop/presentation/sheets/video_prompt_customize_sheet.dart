import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tryzeon/core/theme/app_theme.dart';
import 'package:tryzeon/feature/personal/home/domain/entities/video_prompt_config.dart';
import 'package:tryzeon/feature/personal/settings/providers/settings_providers.dart';

class VideoPromptCustomizeSheet extends HookConsumerWidget {
  const VideoPromptCustomizeSheet({super.key});

  static const List<String> scenePresets = ['純白攝影棚', '都會街頭', '柔焦自然風景'];

  static const List<String> transitionPresets = ['一鏡到底', '動態跳剪', '柔和淡入淡出'];

  static Future<void> show(final BuildContext context) {
    return showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (final context) => const VideoPromptCustomizeSheet(),
    );
  }

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final configAsync = ref.watch(videoPromptConfigProvider);
    final config = configAsync.when(
      data: (final data) => data,
      loading: () => const VideoPromptConfig(),
      error: (_, final _) => const VideoPromptConfig(),
    );

    final sceneController = useTextEditingController(text: config.scenePrompt ?? '');
    final transitionController = useTextEditingController(
      text: config.transitionPrompt ?? '',
    );
    final isSaving = useState(false);

    // Sync controllers when config loads (only on first load)
    final hasInitialized = useRef(false);
    useEffect(() {
      if (!hasInitialized.value && configAsync.hasValue) {
        hasInitialized.value = true;
        configAsync.whenData((final loaded) {
          sceneController.text = loaded.scenePrompt ?? '';
          transitionController.text = loaded.transitionPrompt ?? '';
        });
      }
      return null;
    }, [configAsync.hasValue]);

    Future<void> handleSave() async {
      isSaving.value = true;
      final newConfig = VideoPromptConfig(
        scenePrompt: sceneController.text.trim().isEmpty
            ? null
            : sceneController.text.trim(),
        transitionPrompt: transitionController.text.trim().isEmpty
            ? null
            : transitionController.text.trim(),
      );
      await ref.read(videoPromptConfigProvider.notifier).save(newConfig);
      isSaving.value = false;
      if (context.mounted) Navigator.pop(context);
    }

    void appendChip(final TextEditingController controller, final String chip) {
      // 直接取代輸入框內容
      controller.text = chip;
      // Move cursor to end
      controller.selection = TextSelection.fromPosition(
        TextPosition(offset: controller.text.length),
      );
    }

    return SafeArea(
      bottom: true,
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          MediaQuery.of(context).viewInsets.bottom + AppSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.mdLg),
              child: Row(
                children: [
                  Icon(Icons.edit_note_rounded, color: colorScheme.onSurface, size: 24),
                  const SizedBox(width: AppSpacing.smMd),
                  Text('自訂影片風格', style: textTheme.titleLarge),
                ],
              ),
            ),

            // Scene Section
            Text('場景 Scene', style: textTheme.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: scenePresets
                  .map(
                    (final preset) => ActionChip(
                      label: Text(preset),
                      onPressed: () => appendChip(sceneController, preset),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: sceneController,
              decoration: const InputDecoration(hintText: '例如：純白攝影棚'),
              maxLines: 2,
              minLines: 1,
            ),

            const SizedBox(height: AppSpacing.mdLg),

            // Transition Section
            Text('轉場 Transition', style: textTheme.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: transitionPresets
                  .map(
                    (final preset) => ActionChip(
                      label: Text(preset),
                      onPressed: () => appendChip(transitionController, preset),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: transitionController,
              decoration: const InputDecoration(hintText: '例如：一鏡到底'),
              maxLines: 2,
              minLines: 1,
            ),

            const SizedBox(height: AppSpacing.lg),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: isSaving.value ? null : handleSave,
                child: isSaving.value
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: AppStroke.regular),
                      )
                    : const Text('儲存'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
